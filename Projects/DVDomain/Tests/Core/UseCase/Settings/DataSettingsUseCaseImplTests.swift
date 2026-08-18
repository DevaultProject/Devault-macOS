// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DataSettingsUseCaseImpl")
struct DataSettingsUseCaseImplTests {

    @Test("현재 저장소의 iCloud 동기화 여부를 반환한다")
    func isICloudSyncEnabledReturnsCurrentSetting() {
        let settingsRepository = FakeSettingsRepository()
        settingsRepository.isICloudSyncEnabledValue = true
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: FakeDataResetRepository(),
            settingsRepository: settingsRepository,
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: settingsRepository
            ),
            expiryNotificationScheduler: SpyExpiryNotificationScheduler()
        )

        #expect(sut.isICloudSyncEnabled())
    }

    @Test("인증 후 DataResetRepository에 전체 삭제를 요청한다")
    func deleteAllDataDeletesEverything() async throws {
        let dataResetRepository = FakeDataResetRepository()
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: dataResetRepository,
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            ),
            expiryNotificationScheduler: SpyExpiryNotificationScheduler()
        )

        try await sut.deleteAllData()

        #expect(dataResetRepository.deleteAllCount == 1)
    }

    @Test("전체 삭제에 성공하면 예약된 만료 알림도 모두 취소한다")
    func deleteAllDataCancelsExpiryNotifications() async throws {
        let scheduler = SpyExpiryNotificationScheduler()
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: FakeDataResetRepository(),
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            ),
            expiryNotificationScheduler: scheduler
        )

        try await sut.deleteAllData()

        #expect(scheduler.cancelAllCount == 1)
    }

    @Test("인증에 실패하면 아무것도 삭제하지 않고 알림도 취소하지 않는다")
    func deleteAllDataDoesNothingWhenAuthenticationFails() async {
        let dataResetRepository = FakeDataResetRepository()
        let scheduler = SpyExpiryNotificationScheduler()
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .cancelled
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: dataResetRepository,
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: authenticationService,
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            ),
            expiryNotificationScheduler: scheduler
        )

        await #expect(throws: UserAuthenticationError.cancelled) {
            try await sut.deleteAllData()
        }
        #expect(dataResetRepository.deleteAllCount == 0)
        #expect(scheduler.cancelAllCount == 0)
    }

    @Test("저장소 초기화 실패 시 실패를 전달하고 알림도 취소하지 않는다")
    func deleteAllDataRethrowsDataResetFailure() async {
        let dataResetRepository = FakeDataResetRepository()
        dataResetRepository.error = .resetFailed
        let scheduler = SpyExpiryNotificationScheduler()
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: dataResetRepository,
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            ),
            expiryNotificationScheduler: scheduler
        )

        await #expect(throws: DataResetRepositoryError.resetFailed) {
            try await sut.deleteAllData()
        }
        // 삭제가 실패해 데이터가 남았으므로 알림도 유지되어야 한다.
        #expect(scheduler.cancelAllCount == 0)
    }
}

private final class FakeDataResetRepository: DataResetRepository, @unchecked Sendable {
    var error: DataResetRepositoryError?
    private(set) var deleteAllCount = 0

    func deleteAll() async throws {
        deleteAllCount += 1
        if let error { throw error }
    }
}

private final class SpyExpiryNotificationScheduler: ScheduleSecretExpiryNotificationsUseCase, @unchecked Sendable {
    private(set) var cancelAllCount = 0

    func syncAll() async throws {}
    func schedule(secret: Secret) async {}
    func cancel(secretID: UUID) async {}
    func cancelAll() async { cancelAllCount += 1 }
}
