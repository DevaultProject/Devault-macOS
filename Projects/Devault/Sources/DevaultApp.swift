import SwiftUI

import ComposableArchitecture
import DVPresentation

@main
struct DevaultApp: App {
  var body: some Scene {
    WindowGroup {
      AppView(
        store: Store(initialState: AppFeature.State()) {
          AppFeature()
        }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 800, height: 600)

    WindowGroup("Settings", id: "settings") {
      Text("Settings")
        .frame(width: 500, height: 400)
    }
    .defaultSize(width: 500, height: 400)
  }
}
