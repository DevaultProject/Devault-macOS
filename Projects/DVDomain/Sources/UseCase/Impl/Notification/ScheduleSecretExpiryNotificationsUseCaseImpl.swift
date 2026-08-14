// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

public struct ScheduleSecretExpiryNotificationsUseCaseImpl: ScheduleSecretExpiryNotificationsUseCase {

    /// 지금까지 설정 화면이 제공한 모든 가능한 옵션 — 설정이 바뀌어도 예전에 예약된 마크를
    /// 확실히 취소하기 위해 schedule()이 아니라 cancel()에서만 이 고정 목록을 쓴다.
    static let allPossibleDaysBeforeExpiry = [30, 7, 1, 0]

    private let repository: any SecretRepository
    private let notificationService: any SecurityNotificationService
    private let dateProvider: @Sendable () -> Date
    /// 만료 알림 사용 여부. 꺼져 있으면 기존 예약을 취소만 하고 새로 만들지 않는다.
    private let isEnabled: @Sendable () -> Bool
    /// 호출마다 새로 읽는다 — 설정 화면에서 값을 바꾸면 다음 동기화부터 바로 반영되어야 한다.
    private let daysBeforeExpiry: @Sendable () -> [Int]

    public init(
        repository: any SecretRepository,
        notificationService: any SecurityNotificationService,
        dateProvider: @escaping @Sendable () -> Date = { Date() },
        isEnabled: @escaping @Sendable () -> Bool = { true },
        daysBeforeExpiry: @escaping @Sendable () -> [Int] = { ScheduleSecretExpiryNotificationsUseCaseImpl.allPossibleDaysBeforeExpiry }
    ) {
        self.repository = repository
        self.notificationService = notificationService
        self.dateProvider = dateProvider
        self.isEnabled = isEnabled
        self.daysBeforeExpiry = daysBeforeExpiry
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

        // expiresAt이 바뀌었을 수 있어 이전 마크가 stale하게 남지 않도록 먼저 전부 취소한다.
        await cancel(secretID: secret.id)
        guard isEnabled() else { return }

        let now = dateProvider()
        for daysBefore in daysBeforeExpiry() {
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
        // 현재 설정이 아니라 "가능했던 모든" daysBefore를 취소 — 이미 소비된 것도 무시되니 존재 확인 안함
        let identifiers = Self.allPossibleDaysBeforeExpiry.map { Self.notificationID(secretID: secretID, daysBefore: $0) }
        await notificationService.cancel(identifiers: identifiers)
    }

    private static func notificationID(secretID: UUID, daysBefore: Int) -> String {
        "secret-expiry-\(secretID.uuidString)-\(daysBefore)d"
    }
}
