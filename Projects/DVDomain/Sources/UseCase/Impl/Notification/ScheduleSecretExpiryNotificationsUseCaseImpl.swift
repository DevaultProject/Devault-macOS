// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

public struct ScheduleSecretExpiryNotificationsUseCaseImpl: ScheduleSecretExpiryNotificationsUseCase {

    private static let expiryNotificationHour = 9

    private let repository: any SecretRepository
    private let notificationService: any SecurityNotificationService
    private let settingsRepository: any SettingsRepository
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        notificationService: any SecurityNotificationService,
        settingsRepository: any SettingsRepository,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.notificationService = notificationService
        self.settingsRepository = settingsRepository
        self.dateProvider = dateProvider
    }

    public func syncAll() async throws {
        do {
            let secrets = try await repository.fetch(SecretQuery(collection: .all))
            for secret in secrets {
                // schedule이 만료일 유무와 무관하게 이전 예약을 먼저 취소하므로 분기가 필요 없다 —
                // 만료일이 나중에 제거된 Secret의 정리도 같은 호출이 처리한다.
                await schedule(secret: secret)
            }
        } catch {
            throw SecretUseCaseError.map(error)
        }
    }

    public func schedule(secret: Secret) async {
        // 취소가 guard보다 **앞에** 있어야 한다. expiresAt이 바뀌었으면 옛 마크가 남지 않아야 하고,
        // 지워졌으면 예약을 전부 걷어야 한다 — guard 뒤에 두면 만료일을 지운 Secret에 대해
        // 이 함수가 곧바로 리턴해 이전 알림이 그대로 살아남는다.
        await cancel(secretID: secret.id)

        guard let expiresAt = secret.expiresAt else { return }
        guard settingsRepository.isExpiryAlertsEnabled() else { return }

        let now = dateProvider()
        guard expiresAt > now else { return }
        for timing in settingsRepository.expiryAlertDaysBefore() {
            guard let dayMark = Self.notificationDate(
                expiresAt: expiresAt,
                timing: timing
            ) else {
                continue
            }
            // 이미 지난 마크는 스킵하고 앱을 다시 열었을 때 아직 안 지난 마크만 정상적으로 예약
            guard dayMark > now else { continue }

            let notification = SecurityNotification.secretExpiresSoon(
                secretID: secret.id,
                timing: timing
            )

            do {
                // identifier가 secretID+timing으로 고정돼 있어 반복 호출돼도 덮어쓸 뿐 중복 안됨
                try await notificationService.schedule(
                    ScheduledSecurityNotification(
                        identifier: Self.notificationID(secretID: secret.id, timing: timing),
                        notification: notification,
                        fireDate: dayMark
                    )
                )
            } catch {
                Log.warn("만료 알림 예약 실패(\(secret.id), \(timing.rawValue)일 전): \(error)", category: .notification)
            }
        }
    }

    public func cancel(secretID: UUID) async {
        // 현재 선택과 관계없이 Domain이 정의한 모든 알림 시점을 취소해 이전 예약이 남지 않게 한다.
        let identifiers = ExpiryAlertDay.allCases.map {
            Self.notificationID(secretID: secretID, timing: $0)
        }
        await notificationService.cancel(identifiers: identifiers)
    }

    private static func notificationID(secretID: UUID, timing: ExpiryAlertDay) -> String {
        "secret-expiry-\(secretID.uuidString)-\(timing.rawValue)d"
    }

    private static func notificationDate(expiresAt: Date, timing: ExpiryAlertDay) -> Date? {
        let calendar = Calendar.current
        guard let notificationDay = calendar.date(
            byAdding: .day,
            value: -timing.rawValue,
            to: expiresAt
        ) else { return nil }

        return calendar.date(
            bySettingHour: expiryNotificationHour,
            minute: 0,
            second: 0,
            of: notificationDay
        )
    }
}
