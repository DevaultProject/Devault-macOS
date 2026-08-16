// Copyright © 2026 Devault. All rights reserved

import DVCore
import SwiftData

public final class LocalStorage {
    public let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func makeDefault(iCloudSyncEnabled: Bool) throws -> LocalStorage {
        // local/cloud 모드 모두 같은 "Synced" 저장소를 사용한다. 동기화를 꺼도 이 Mac의
        // 데이터와 CloudKit 데이터는 삭제하지 않고, CloudKit mirroring만 비활성화한다.
        // 다시 켜면 같은 로컬 저장소가 CloudKit과 변경사항을 병합한다.
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
