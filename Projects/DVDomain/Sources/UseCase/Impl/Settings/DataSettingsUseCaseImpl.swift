// Copyright © 2026 Devault. All rights reserved

public struct DataSettingsUseCaseImpl: DataSettingsUseCase {
    private let dataResetRepository: any DataResetRepository
    private let settingsRepository: any SettingsRepository
    private let authenticateUseCase: any AuthenticateUseCase
    private let expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase

    public init(
        dataResetRepository: any DataResetRepository,
        settingsRepository: any SettingsRepository,
        authenticateUseCase: any AuthenticateUseCase,
        expiryNotificationScheduler: any ScheduleSecretExpiryNotificationsUseCase
    ) {
        self.dataResetRepository = dataResetRepository
        self.settingsRepository = settingsRepository
        self.authenticateUseCase = authenticateUseCase
        self.expiryNotificationScheduler = expiryNotificationScheduler
    }

    public func isICloudSyncEnabled() -> Bool {
        settingsRepository.isICloudSyncEnabled()
    }

    public func deleteAllData() async throws {
        try await authenticateUseCase.authenticate(reason: "Delete all data")
        try await dataResetRepository.deleteAll()
        // 데이터가 사라졌으니 예약된 만료 알림도 함께 걷어낸다. 삭제 성공 후에만 취소해,
        // 삭제가 실패하면(데이터가 남으면) 알림도 그대로 유지되게 한다.
        await expiryNotificationScheduler.cancelAll()
    }
}
