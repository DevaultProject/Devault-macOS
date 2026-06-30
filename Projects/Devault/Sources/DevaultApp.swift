import DVData
import SwiftUI

@main
struct DevaultApp: App {
    private let storageResult: Result<LocalStorage, Error>

    init() {
        self.storageResult = Result {
            try LocalStorage.makeDefault()
        }
    }

    var body: some Scene {
        WindowGroup {
            switch storageResult {
            case let .success(storage):
                ContentView(storage: storage)
            case let .failure(error):
                StorageUnavailableView(error: error)
            }
        }
    }
}
