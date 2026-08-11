// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("ScheduleSecretExpiryNotificationsUseCaseImpl")
struct ScheduleSecretExpiryNotificationsUseCaseImplTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let day: TimeInterval = 86_400

    // MARK: - schedule(secret:)

    @Test("만료가 5일 남았으면 7일 전 알림은 건너뛰고 3일 전 알림만 예약한다")
    func scheduleSkipsPastFireDates() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(5 * day))

        await sut.schedule(secret: secret)

        let identifiers = Set(notificationService.scheduled.map(\.identifier))
        #expect(identifiers == [
            "secret-expiry-\(secret.id.uuidString)-3d",
        ])
    }

    @Test("만료가 10일 남았으면 7일/3일 전 알림을 모두 예약한다")
    func scheduleSchedulesAllWhenFarEnough() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(10 * day))

        await sut.schedule(secret: secret)

        let identifiers = Set(notificationService.scheduled.map(\.identifier))
        #expect(identifiers == [
            "secret-expiry-\(secret.id.uuidString)-7d",
            "secret-expiry-\(secret.id.uuidString)-3d",
        ])
    }

    @Test("마크가 정확히 지금과 같으면(만료 기간이 daysBefore와 우연히 일치) 스킵한다")
    func scheduleSkipsWhenMarkExactlyMatchesNow() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        
        // 3일 전 마크가 정확히 "지금"과 같은 경우 — 이미 지난 것으로 보고 스킵한다.
        let expiresAt = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        let secret = SecretFixture.make(expiresAt: expiresAt)

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
    }

    @Test("expiresAt이 바뀌면 재예약 전에 이전 마크를 먼저 취소한다")
    func scheduleCancelsPreviousMarksBeforeReschedulingWhenExpiryChanges() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000DD")!
        let farSecret = SecretFixture.make(id: secretID, expiresAt: now.addingTimeInterval(10 * day))
        let nearSecret = SecretFixture.make(id: secretID, expiresAt: now.addingTimeInterval(2 * day))

        await sut.schedule(secret: farSecret)
        await sut.schedule(secret: nearSecret)

        // schedule()이 매번 먼저 cancel하므로, 두 번 호출하면 cancel도 두 번 일어나야 stale한 -7d가 안 남는다.
        #expect(notificationService.cancelledIdentifiers.count == 2)
        #expect(notificationService.cancelledIdentifiers.allSatisfy {
            $0 == [
                "secret-expiry-\(secretID.uuidString)-7d",
                "secret-expiry-\(secretID.uuidString)-3d",
            ]
        })
    }

    @Test("만료일이 없으면 아무 알림도 예약하지 않는다")
    func scheduleDoesNothingWithoutExpiresAt() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: nil)

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
    }

    // MARK: - cancel(secretID:)

    @Test("cancel은 7일/3일 알림 ID를 모두 취소 요청한다")
    func cancelCancelsAllIdentifiers() async {
        let notificationService = FakeSecurityNotificationService()
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: InMemorySecretRepository(),
            notificationService: notificationService,
            dateProvider: { self.now }
        )
        let secretID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!

        await sut.cancel(secretID: secretID)

        #expect(notificationService.cancelledIdentifiers == [[
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
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
            dateProvider: { self.now }
        )

        try await sut.syncAll()

        #expect(notificationService.scheduled.allSatisfy { $0.identifier.contains(withExpiry.id.uuidString) })
        #expect(notificationService.scheduled.count == 2)
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
            dateProvider: { self.now }
        )

        try await sut.syncAll()

        #expect(notificationService.cancelledIdentifiers == [[
            "secret-expiry-\(secretID.uuidString)-7d",
            "secret-expiry-\(secretID.uuidString)-3d",
        ]])
    }

    @Test("syncAll은 repository 에러를 SecretUseCaseError로 매핑해 던진다")
    func syncAllMapsRepositoryError() async {
        let repository = InMemorySecretRepository()
        repository.errorOnFetchQuery = .storageUnavailable
        let sut = ScheduleSecretExpiryNotificationsUseCaseImpl(
            repository: repository,
            notificationService: FakeSecurityNotificationService(),
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
            dateProvider: { self.now }
        )
        let secret = SecretFixture.make(expiresAt: now.addingTimeInterval(10 * day))

        await sut.schedule(secret: secret)

        #expect(notificationService.scheduled.isEmpty)
    }
}
