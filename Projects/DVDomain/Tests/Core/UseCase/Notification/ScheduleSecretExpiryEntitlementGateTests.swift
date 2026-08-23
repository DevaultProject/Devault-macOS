// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

/// 무료 등급의 만료 알림 개수 제한(설계 §4-4)을 검증한다.
///
/// **저장된 설정은 건드리지 않고 스케줄만 줄인다.** 지우면 재구독 시 복원할 수 없다.
@Suite("ScheduleSecretExpiryNotificationsUseCaseImpl 등급 게이트")
struct ScheduleSecretExpiryEntitlementGateTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let day: TimeInterval = 86_400

    private func makeSUT(
        entitlement: Entitlement,
        selected: [ExpiryAlertDay]
    ) -> (ScheduleSecretExpiryNotificationsUseCaseImpl, FakeSecurityNotificationService, FakeSettingsRepository) {
        let notificationService = FakeSecurityNotificationService()
        let settings = FakeSettingsRepository()
        settings.expiryAlertDaysBeforeValue = selected
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: settings,
            entitlementUseCase: StubEntitlementUseCase(entitlement: entitlement),
            dateProvider: { self.now }
        )
        return (sut, notificationService, settings)
    }

    /// 예약된 알림에서 시점만 뽑는다. identifier가 `...-<일수>d` 꼴이라 마지막 조각에서 `d`를 떼고 읽는다.
    private func scheduledTimings(_ service: FakeSecurityNotificationService) -> [Int] {
        service.scheduled.compactMap {
            Int($0.identifier.split(separator: "-").last?.dropLast() ?? "")
        }
    }

    @Test("Pro는 선택한 시점을 모두 예약한다")
    func proSchedulesAllSelected() async {
        let (sut, service, _) = makeSUT(entitlement: .pro, selected: ExpiryAlertDay.allCases)
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(service.scheduled.count == ExpiryAlertDay.allCases.count)
    }

    @Test("무료는 선택한 것 중 가장 이른 하나만 예약한다")
    func freeSchedulesOnlyEarliest() async {
        let (sut, service, _) = makeSUT(entitlement: .free, selected: ExpiryAlertDay.allCases)
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(service.scheduled.count == EntitlementLimits.maxExpiryAlertDays)
        #expect(scheduledTimings(service) == [ExpiryAlertDay.thirtyDaysBefore.rawValue])
    }

    @Test("7일 전을 꺼도 알림이 0건이 되지 않는다 — 남은 것 중 가장 이른 하나가 예약된다")
    func freeFallsBackWhenSevenDayIsDeselected() async {
        let (sut, service, _) = makeSUT(
            entitlement: .free,
            selected: [.threeDaysBefore, .expirationDay]
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(scheduledTimings(service) == [ExpiryAlertDay.threeDaysBefore.rawValue])
    }

    @Test("아무 시점도 고르지 않으면 무료도 예약하지 않는다 — 사용자 의도를 존중한다")
    func freeSchedulesNothingWhenNoneSelected() async {
        let (sut, service, _) = makeSUT(entitlement: .free, selected: [])
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(service.scheduled.isEmpty)
    }

    @Test("무료로 축소해도 저장된 설정은 그대로 남는다 — 재구독 시 복원돼야 한다")
    func freeDoesNotMutateStoredSelection() async {
        let selected = ExpiryAlertDay.allCases
        let (sut, _, settings) = makeSUT(entitlement: .free, selected: selected)
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(settings.expiryAlertDaysBefore() == selected)
    }
}
