// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

public struct ScheduleSecretExpiryNotificationsUseCaseImpl: ScheduleSecretExpiryNotificationsUseCase {

    private static let expiryNotificationHour = 9
    private static let expiryIDPrefix = "secret-expiry-"

    private let repository: any SecretRepository
    private let notificationService: any SecurityNotificationService
    private let settingsRepository: any SettingsRepository
    private let entitlementUseCase: any EntitlementUseCase
    private let dateProvider: @Sendable () -> Date

    public init(
        repository: any SecretRepository,
        notificationService: any SecurityNotificationService,
        settingsRepository: any SettingsRepository,
        entitlementUseCase: any EntitlementUseCase,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.notificationService = notificationService
        self.settingsRepository = settingsRepository
        self.entitlementUseCase = entitlementUseCase
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
            // 조회에 잡히지 않는(원격 삭제·전체 삭제 등으로 사라진) Secret의 고아 예약을 걷어낸다.
            // 개별 취소는 ID를 알아야 하지만, pending 목록과 현재 Secret 집합의 차집합으로 특정한다.
            await cancelOrphans(existing: secrets)
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
        for timing in scheduledTimings(expiresAt: expiresAt, now: now) {
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

    public func cancelAll() async {
        let expiry = await pendingExpiryIdentifiers()
        guard !expiry.isEmpty else { return }
        await notificationService.cancel(identifiers: expiry)
    }

    /// 현재 존재하는 Secret 집합에 속하지 않는 만료 알림(고아)을 취소한다.
    /// 원격 삭제된 Secret은 조회 결과에 없어 ID를 모르므로, pending 목록에서 유효 식별자 집합의
    /// 차집합으로 특정한다.
    private func cancelOrphans(existing secrets: [Secret]) async {
        let valid = Set(secrets.flatMap { secret in
            ExpiryAlertDay.allCases.map { Self.notificationID(secretID: secret.id, timing: $0) }
        })
        let orphans = await pendingExpiryIdentifiers().filter { !valid.contains($0) }
        guard !orphans.isEmpty else { return }
        await notificationService.cancel(identifiers: orphans)
    }

    /// pending 알림 중 만료 알림 식별자만 골라 반환한다(다른 종류의 알림은 건드리지 않는다).
    private func pendingExpiryIdentifiers() async -> [String] {
        await notificationService.pendingIdentifiers().filter { $0.hasPrefix(Self.expiryIDPrefix) }
    }

    private static func notificationID(secretID: UUID, timing: ExpiryAlertDay) -> String {
        "\(expiryIDPrefix)\(secretID.uuidString)-\(timing.rawValue)d"
    }

    /// 이번 Secret에 실제로 예약할 알림 시점. 무료 등급이면 개수를 ``EntitlementLimits/maxExpiryAlertDays``로 줄인다.
    ///
    /// **저장된 설정은 건드리지 않고 읽은 값을 줄이기만 한다** — 지우면 재구독 시 복원할 수 없다(설계 §2).
    ///
    /// 남길 하나는 **가장 이른 시점**이다. 시크릿 교체에는 시간이 필요해서 만료에 가까운 알림은 대응할 여유를 주지 못한다. 특정 시점을 고정하지 않는 이유는 ``EntitlementLimits/maxExpiryAlertDays``에 적었다.
    /// - Parameters:
    ///   - expiresAt: 이 Secret의 만료 시각
    ///   - now: 지났는지 판단할 기준 시각
    /// - Returns: 예약할 시점 목록. 사용자가 아무 시점도 고르지 않았으면 빈 배열
    private func scheduledTimings(expiresAt: Date, now: Date) -> [ExpiryAlertDay] {
        let selected = settingsRepository.expiryAlertDaysBefore()
        guard !entitlementUseCase.canUseMultipleExpiryAlertDays() else { return selected }

        // **아직 지나지 않은 시점 중에서** 고른다. 지난 것까지 후보에 넣으면, 만료가 10일 남았는데 30일 전이 선택돼 있을 때 그것 하나만 남고 예약 단계에서 걸러져 알림이 0건이 된다.
        let upcoming = selected.filter { timing in
            guard let mark = Self.notificationDate(expiresAt: expiresAt, timing: timing) else { return false }
            return mark > now
        }
        // rawValue가 만료 전 일수라 큰 쪽이 이르다.
        let earliestFirst = upcoming.sorted { $0.rawValue > $1.rawValue }
        return Array(earliestFirst.prefix(EntitlementLimits.maxExpiryAlertDays))
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
