// Copyright © 2026 Devault. All rights reserved

import SwiftData

public final class LocalStorage {
    public static let shared = LocalStorage()

    private init() { }

    public lazy var modelContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: Schema.appSchema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
