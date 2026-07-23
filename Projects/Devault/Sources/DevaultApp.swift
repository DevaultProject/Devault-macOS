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
      .ignoresSafeArea()
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 800, height: 600)
  }
}
