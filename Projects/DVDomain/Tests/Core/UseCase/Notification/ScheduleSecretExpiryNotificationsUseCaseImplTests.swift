// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("ScheduleSecretExpiryNotificationsUseCaseImpl")
struct ScheduleSecretExpiryNotificationsUseCaseImplTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let day: TimeInterval = 86_400

    // MARK: - schedule(secret:)

    @Test("만료가 40일 남았으면 30/7/3일 전·당일 알림을 모두 예약한다")
    func scheduleSchedulesAllMarksWhenFarEnough() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        let identifiers = Set(notificationService.scheduled.map(\.identifier))
        #expect(identifiers == [
            "secret-expiry-\(secret.id.uuidString)-30d",
            "secret-expiry-\(secret.id.uuidString)-7d",
            "secret-expiry-\(secret.id.uuidString)-3d",
            "secret-expiry-\(secret.id.uuidString)-0d",
        ])
    }

    @Test("만료가 5일 남았으면 지난 마크(30/7일 전)는 건너뛰고 3일 전·당일만 예약한다")
    func scheduleSkipsPastMarks() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(5 * day))

        await sut.schedule(secret: secret)

        let identifiers = Set(notificationService.scheduled.map(\.identifier))
        #expect(identifiers == [
            "secret-expiry-\(secret.id.uuidString)-3d",
            "secret-expiry-\(secret.id.uuidString)-0d",
        ])
    }

    @Test("모든 만료 알림은 해당 날짜 오전 9시에 예약한다")
    func scheduleAllExpirationAlertsAtNineAM() async throws {
        let calendar = Calendar.current
        let expiresAt = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 59, second: 59)
        ))
        let now = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 1, hour: 12)
        ))
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { now }
        )
        let secret = SecretFixture.make(expiresAt: expiresAt)

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.count == 4)
        for scheduled in notificationService.scheduled {
            let components = calendar.dateComponents(
                [.hour, .minute, .second],
                from: scheduled.fireDate
            )
            #expect(components.hour == 9)
            #expect(components.minute == 0)
            #expect(components.second == 0)
        }
    }

    @Test("이미 만료됐으면(마크가 전부 지금과 같거나 지남) 아무 알림도 예약하지 않는다")
    func scheduleSkipsWhenAlreadyExpired() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now)

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
    }

    @Test("expiresAt이 바뀌면 재예약 전에 이전 마크를 먼저 취소한다")
    func scheduleCancelsPreviousMarksBeforeReschedulingWhenExpiryChanges() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000DD")!
        let farSecret = SecretFixture.make(id: secretID, expiresAt: now.addingTimeInterval(40 * day))
        let nearSecret = SecretFixture.make(id: secretID, expiresAt: now.addingTimeInterval(2 * day))

        await sut.schedule(secret: farSecret)
        await sut.schedule(secret: nearSecret)

        // schedule()이 매번 먼저 cancel하므로, 두 번 호출하면 cancel도 두 번 일어나야 stale한 마크가 안 남는다.
        #expect(notificationService.cancelledIdentifiers.count == 2)
        #expect(notificationService.cancelledIdentifiers.allSatisfy {
            $0 == [
                "secret-expiry-\(secretID.uuidString)-30d",
                "secret-expiry-\(secretID.uuidString)-7d",
                "secret-expiry-\(secretID.uuidString)-3d",
                "secret-expiry-\(secretID.uuidString)-0d",
            ]
        })
    }

    @Test("만료일이 없으면 예약하지 않고, 이전 예약은 취소한다")
    func scheduleCancelsAndSchedulesNothingWithoutExpiresAt() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000CC")!
        let secret = SecretFixture.make(id: secretID, expiresAt: nil)

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
        // 수정 화면에서 만료일을 지우는 경로가 이 취소에 의존한다. 취소가 만료일 guard보다
        // 뒤에 있으면 이 함수가 곧바로 리턴해 이전 알림이 그대로 남는다.
        #expect(notificationService.cancelledIdentifiers == [[
            "secret-expiry-\(secretID.uuidString)-30d",
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
            "secret-expiry-\(secretID.uuidString)-0d",
        ]])
    }

    @Test("만료일을 지운 Secret으로 다시 예약을 맞추면 이전 알림이 사라진다")
    func scheduleClearsPreviousMarksWhenExpiryRemoved() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000DD")!
        let scheduled = SecretFixture.make(id: secretID, expiresAt: now.addingTimeInterval(10 * day))

        // 30일 전 마크는 이미 지났고 7일 전·3일 전·당일이 남는다.
        await sut.schedule(secret: scheduled)
        #expect(notificationService.scheduled.count == 3)

        // 사용자가 만료일을 지우고 저장한 상황.
        var cleared = scheduled
        cleared.expiresAt = nil
        await sut.schedule(secret: cleared)

        // 두 번째 호출은 새로 예약하지 않고 취소만 한다.
        #expect(notificationService.scheduled.count == 3)
        #expect(notificationService.cancelledIdentifiers.count == 2)
        #expect(notificationService.cancelledIdentifiers.last == [
            "secret-expiry-\(secretID.uuidString)-30d",
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
            "secret-expiry-\(secretID.uuidString)-0d",
        ])
    }

    @Test("만료 알림 사용이 꺼져 있으면 기존 예약만 취소하고 새로 만들지 않는다")
    func scheduleSkipsCreatingWhenDisabled() async {
        let notificationService = FakeSecurityNotificationService()
        let settingsRepository = FakeSettingsRepository()
        settingsRepository.isExpiryAlertsEnabledValue = false
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: settingsRepository,
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
        #expect(notificationService.cancelledIdentifiers.count == 1)
    }

    @Test("daysBeforeExpiry 설정이 지정한 값만 예약한다")
    func scheduleUsesConfiguredDaysBeforeExpiry() async {
        let notificationService = FakeSecurityNotificationService()
        let settingsRepository = FakeSettingsRepository()
        settingsRepository.expiryAlertDaysBeforeValue = [.sevenDaysBefore]
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: settingsRepository,
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        let identifiers = Set(notificationService.scheduled.map(\.identifier))
        #expect(identifiers == ["secret-expiry-\(secret.id.uuidString)-7d"])
    }

    // MARK: - cancel(secretID:)

    @Test("cancel은 Domain이 정의한 모든(30/7/3일 전·당일) 알림 ID를 취소 요청한다")
    func cancelCancelsAllPossibleIdentifiers() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!

        await sut.cancel(secretID: secretID)

        #expect(notificationService.cancelledIdentifiers == [[
            "secret-expiry-\(secretID.uuidString)-30d",
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
            "secret-expiry-\(secretID.uuidString)-0d",
        ]])
    }

    // MARK: - syncAll()

    @Test("syncAll은 만료일이 있는 Secret만 예약한다")
    func syncAllSchedulesOnlySecretsWithExpiresAt() async throws {
        let repository = InMemorySecretRepository()
        let withExpiry = SecretFixture.make(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
            expiresAt: now.addingTimeInterval(10 * day)
        )
        let withoutExpiry = SecretFixture.make(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000CC")!,
            expiresAt: nil
        )
        repository.seed(withExpiry)
        repository.seed(withoutExpiry)

        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: repository,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )

        try await sut.syncAll()

        #expect(notificationService.scheduled.allSatisfy { $0.identifier.contains(withExpiry.id.uuidString) })
        // 10일 후 만료 → 7일 전/3일 전/당일 3개 마크가 미래에 해당
        #expect(notificationService.scheduled.count == 3)
    }

    @Test("syncAll은 expiresAt이 없는(나중에 제거됐을 수 있는) Secret의 예약도 취소한다")
    func syncAllCancelsSecretsWhoseExpiryWasRemoved() async throws {
        let repository = InMemorySecretRepository()
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000EE")!
        let secret = SecretFixture.make(id: secretID, expiresAt: nil)
        repository.seed(secret)

        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: repository,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )

        try await sut.syncAll()

        #expect(notificationService.cancelledIdentifiers == [[
            "secret-expiry-\(secretID.uuidString)-30d",
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
            "secret-expiry-\(secretID.uuidString)-0d",
        ]])
    }

    @Test("syncAll은 repository 에러를 SecretUseCaseError로 매핑해 던진다")
    func syncAllMapsRepositoryError() async {
        let repository = InMemorySecretRepository()
        repository.errorOnFetchQuery = .storageUnavailable
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: repository,
            notificationService: FakeSecurityNotificationService(),
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )

        await #expect(throws: SecretUseCaseError.repositoryFailure(.storageUnavailable)) {
            try await sut.syncAll()
        }
    }

    @Test("notificationService.schedule이 실패해도 throw하지 않고 삼킨다")
    func scheduleSwallowsNotificationServiceFailure() async {
        let notificationService = FakeSecurityNotificationService()
        notificationService.errorOnSchedule = .scheduleFailed
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(40 * day))

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
    }

    @Test("syncAll은 더 이상 존재하지 않는(원격 삭제된) Secret의 고아 예약을 취소한다")
    func syncAllCancelsOrphanNotificationsForVanishedSecrets() async throws {
        let repository = InMemorySecretRepository()
        let existing = SecretFixture.make(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
            expiresAt: now.addingTimeInterval(10 * day)
        )
        repository.seed(existing)

        let notificationService = FakeSecurityNotificationService()
        // 이전 세션에 예약됐지만 지금은 repo에 없는(원격 삭제된) Secret의 알림.
        let orphanID = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!
        notificationService.seedPending([
            "secret-expiry-\(orphanID.uuidString)-30d",
            "secret-expiry-\(orphanID.uuidString)-7d",
        ])
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: repository,
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )

        try await sut.syncAll()

        let pending = Set(await notificationService.pendingIdentifiers())
        // 고아 알림은 사라지고
        #expect(!pending.contains("secret-expiry-\(orphanID.uuidString)-30d"))
        #expect(!pending.contains("secret-expiry-\(orphanID.uuidString)-7d"))
        // 존재하는 Secret의 예약은 남는다(10일 후 만료 → 7일 전 마크가 미래).
        #expect(pending.contains("secret-expiry-\(existing.id.uuidString)-7d"))
    }

    // MARK: - cancelAll()

    @Test("cancelAll은 예약된 모든 만료 알림을 취소하고, 만료 알림이 아닌 것은 건드리지 않는다")
    func cancelAllCancelsAllPendingExpiryNotificationsOnly() async {
        let notificationService = FakeSecurityNotificationService()
        let idA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let idB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!
        notificationService.seedPending([
            "secret-expiry-\(idA.uuidString)-30d",
            "secret-expiry-\(idB.uuidString)-3d",
            "some-other-notification", // 만료 알림 접두어가 아니므로 유지되어야 한다
        ])
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            settingsRepository: FakeSettingsRepository(),
            dateProvider: { self.now }
        )

        await sut.cancelAll()

        let pending = Set(await notificationService.pendingIdentifiers())
        #expect(!pending.contains("secret-expiry-\(idA.uuidString)-30d"))
        #expect(!pending.contains("secret-expiry-\(idB.uuidString)-3d"))
        #expect(pending == ["some-other-notification"])
    }
}
