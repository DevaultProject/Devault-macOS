// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

public struct ScheduleSecretExpiryNotificationsUseCaseImpl: ScheduleSecretExpiryNotificationsUseCase {
    private static let daysBeforeExpiry = [7, 3]

    private let repository: any SecretRepository
    private let notificationService: any SecurityNotificationService
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        notificationService: any SecurityNotificationService,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.notificationService = notificationService
        self.dateProvider = dateProvider
    }

    public func syncAll() async throws {
        do {
            let secrets = try await repository.fetch(SecretQuery(collection: .all))
            for secret in secrets where secret.expiresAt != nil {
                await schedule(secret: secret)
            }
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func schedule(secret: Secret) async {
        guard let expiresAt = secret.expiresAt else { return }
        let now = dateProvider()

        for daysBefore in Self.daysBeforeExpiry {
            guard
                let fireDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiresAt),
                // 이미 지난 마크는 스킵하고 앱을 다시 열었을 때 아직 안 지난 마크만 정상적으로 예약됨
                fireDate > now
            else { continue }

            do {
                // identifier가 secretID+daysBefore로 고정돼 있어,
                // syncAll()이 앱 실행마다 반복 호출돼도 같은 예약을 덮어쓸 뿐 중복·재발송 안됨
                try await notificationService.schedule(
                    ScheduledSecurityNotification(
                        identifier: Self.notificationID(secretID: secret.id, daysBefore: daysBefore),
                        notification: .secretExpiresSoon(secretID: secret.id, name: secret.name, daysBefore: daysBefore),
                        fireDate: fireDate
                    )
                )
            } catch {
                Log.warn("만료 알림 예약 실패(\(secret.id), \(daysBefore)일 전): \(error)", category: .notification)
            }
        }
    }

    public func cancel(secretID: UUID) async {
        // daysBeforeExpiry에 대응하는 identifier를 전부 취소
        // 이미 발송/소비된 identifier를 취소해도 시스템은 별다른 부작용 없이 무시하므로 존재 여부를 따로 확인 안함
        let identifiers = Self.daysBeforeExpiry.map { Self.notificationID(secretID: secretID, daysBefore: $0) }
        await notificationService.cancel(identifiers: identifiers)
    }

    private static func notificationID(secretID: UUID, daysBefore: Int) -> String {
        "secret-expiry-\(secretID.uuidString)-\(daysBefore)d"
    }
}
