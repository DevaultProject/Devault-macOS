// Copyright © 2026 Devault. All rights reserved

public struct DataSettingsUseCaseImpl: DataSettingsUseCase {
    private let dataResetRepository: any DataResetRepository
    private let settingsRepository: any SettingsRepository
    private let authenticateUseCase: any AuthenticateUseCase

    public init(
        dataResetRepository: any DataResetRepository,
        settingsRepository: any SettingsRepository,
        authenticateUseCase: any AuthenticateUseCase
    ) {
        self.dataResetRepository = dataResetRepository
        self.settingsRepository = settingsRepository
        self.authenticateUseCase = authenticateUseCase
    }

    public func isICloudSyncEnabled() -> Bool {
        settingsRepository.isICloudSyncEnabled()
    }

    public func deleteAllData() async throws {
        try await authenticateUseCase.authenticate(reason: "Delete all data")
        try await dataResetRepository.deleteAll()
    }
}
