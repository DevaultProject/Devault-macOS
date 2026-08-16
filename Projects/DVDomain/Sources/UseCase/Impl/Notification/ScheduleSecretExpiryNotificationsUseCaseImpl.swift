// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

public struct ScheduleSecretExpiryNotificationsUseCaseImpl: ScheduleSecretExpiryNotificationsUseCase {
    /// `SecretExpiryPolicy`와 값이 같지만 우연일 뿐 의도적 결합 아님 — `cancel`이 이 값으로
    /// identifier를 재구성해서, 참조하면 값 변경 시 이전 예약을 못 지운다.
    private static let notificationLeadDays = [7, 3]

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
            for secret in secrets {
                if secret.expiresAt != nil {
                    await schedule(secret: secret)
                } else {
                    // expiresAt이 나중에 제거됐을 수 있으므로 이전 예약을 명시적으로 취소한다.
                    await cancel(secretID: secret.id)
                }
            }
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func schedule(secret: Secret) async {
        guard let expiresAt = secret.expiresAt else { return }
        let now = dateProvider()

        // expiresAt이 바뀌었을 수 있어 이전 마크가 stale하게 남지 않도록 먼저 전부 취소한다.
        await cancel(secretID: secret.id)

        for daysBefore in Self.notificationLeadDays {
            guard let dayMark = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiresAt) else {
                continue
            }
            // 이미 지난 마크는 스킵하고 앱을 다시 열었을 때 아직 안 지난 마크만 정상적으로 예약
            guard dayMark > now else { continue }

            let notification = SecurityNotification.secretExpiresSoon(
                secretID: secret.id, daysBefore: daysBefore
            )

            do {
                // identifier가 secretID+daysBefore로 고정돼 있어 반복 호출돼도 덮어쓸 뿐 중복 안됨
                try await notificationService.schedule(
                    ScheduledSecurityNotification(
                        identifier: Self.notificationID(secretID: secret.id, daysBefore: daysBefore),
                        notification: notification,
                        fireDate: dayMark
                    )
                )
            } catch {
                Log.warn("만료 알림 예약 실패(\(secret.id), \(daysBefore)일 전): \(error)", category: .notification)
            }
        }
    }

    public func cancel(secretID: UUID) async {
        // notificationLeadDays에 대응하는 identifier를 전부 취소 — 이미 소비된 것도 무시되니 존재 확인 안함
        let identifiers = Self.notificationLeadDays.map { Self.notificationID(secretID: secretID, daysBefore: $0) }
        await notificationService.cancel(identifiers: identifiers)
    }

    private static func notificationID(secretID: UUID, daysBefore: Int) -> String {
        "secret-expiry-\(secretID.uuidString)-\(daysBefore)d"
    }
}
