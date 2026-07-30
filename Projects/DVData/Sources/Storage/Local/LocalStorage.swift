// Copyright © 2026 Devault. All rights reserved

import SwiftData

public final class LocalStorage {
    public let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func makeDefault(iCloudSyncEnabled: Bool) throws -> LocalStorage {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudSyncEnabled ? .private("iCloud.com.devault.app") : .none
        )
        let modelContainer = try ModelContainer(
            for: Schema.appSchema,
            configurations: configuration
        )

        return LocalStorage(modelContainer: modelContainer)
    }
}
