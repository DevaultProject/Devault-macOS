// Copyright © 2026 Devault. All rights reserved

import DVCore
import SwiftData

public final class LocalStorage {
    public let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func makeDefault(iCloudSyncEnabled: Bool) throws -> LocalStorage {
        let syncedConfiguration = ModelConfiguration(
            "Synced",
            schema: Schema.syncedSchema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudSyncEnabled ? .private(ICloudContainer.identifier) : .none
        )
        let localOnlyConfiguration = ModelConfiguration(
            "LocalOnly",
            schema: Schema.localOnlySchema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        let modelContainer = try ModelContainer(
            for: Schema.appSchema,
            configurations: syncedConfiguration, localOnlyConfiguration
        )

        return LocalStorage(modelContainer: modelContainer)
    }
}
