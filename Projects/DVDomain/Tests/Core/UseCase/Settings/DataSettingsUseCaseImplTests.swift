// Copyright © 2026 Devault. All rights reserved

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
            )
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
            )
        )

        try await sut.deleteAllData()

        #expect(dataResetRepository.deleteAllCount == 1)
    }

    @Test("인증에 실패하면 아무것도 삭제하지 않는다")
    func deleteAllDataDoesNothingWhenAuthenticationFails() async {
        let dataResetRepository = FakeDataResetRepository()
        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .cancelled
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: dataResetRepository,
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: authenticationService,
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            )
        )

        await #expect(throws: UserAuthenticationError.cancelled) {
            try await sut.deleteAllData()
        }
        #expect(dataResetRepository.deleteAllCount == 0)
    }

    @Test("저장소 초기화 실패를 그대로 전달한다")
    func deleteAllDataRethrowsDataResetFailure() async {
        let dataResetRepository = FakeDataResetRepository()
        dataResetRepository.error = .resetFailed
        let sut = DataSettingsUseCaseImpl(
            dataResetRepository: dataResetRepository,
            settingsRepository: FakeSettingsRepository(),
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService(),
                settingsRepository: FakeSettingsRepository()
            )
        )

        await #expect(throws: DataResetRepositoryError.resetFailed) {
            try await sut.deleteAllData()
        }
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
