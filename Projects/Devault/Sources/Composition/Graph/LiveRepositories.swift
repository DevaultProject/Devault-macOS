// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain

/// Composition Root 전체에서 공유하는 Repository 인스턴스.
/// Secret/Project는 안정적인 Proxy이며, iCloud 설정이 바뀌면 내부 Repository만 교체된다.
enum LiveRepositories {
    static let settings: any SettingsRepository = SettingsRepositoryImpl()
    static let storage = LiveStorage(settingsRepository: settings)
    static let secret: any SecretRepository = LiveSecretRepository(storage: storage)
    static let project: any ProjectRepository = LiveProjectRepository(storage: storage)
    static let dataReset: any DataResetRepository = LiveDataResetRepository(storage: storage)
}
