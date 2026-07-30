// Copyright © 2026 Devault. All rights reserved

import SwiftData

public final class LocalStorage {
    public let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func makeDefault() throws -> LocalStorage {
        // cloudKitDatabase 기본값(.automatic)은 앱에 iCloud entitlement가 있으면 CloudKit 미러링을 시도한다.
        // 현재 모델들은 CloudKit이 지원하지 않는 @Attribute(.unique)를 쓰고 있어 그대로 두면 초기화가 실패하므로 명시적으로 끈다.
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        let modelContainer = try ModelContainer(
            for: Schema.appSchema,
            configurations: configuration
        )

        return LocalStorage(modelContainer: modelContainer)
    }
}
