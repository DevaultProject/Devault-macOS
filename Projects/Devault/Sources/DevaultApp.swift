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
      // minWidth: 사이드바(200) + SelectSecretType 그리드 요구 너비(약 700)를 담을 수 있는 하한.
      // 이보다 좁아지면 그리드 열이 찌그러져 카드가 겹친다.
      .frame(
        minWidth: 920,
        maxWidth: .infinity,
        minHeight: 600,
        maxHeight: .infinity
      )
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 960, height: 700)

    WindowGroup("Settings", id: "settings") {
      Text("Settings")
        .frame(width: 500, height: 400)
    }
    .defaultSize(width: 500, height: 400)
  }
}
