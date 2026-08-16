import SwiftUI
import UserNotifications

import ComposableArchitecture
import DVPresentation

@main
struct DevaultApp: App {

  /// ViewBuilder 안에서 만들면 body가 재평가될 때마다 Store가 새로 생성되어 상태가 날아간다.
  private let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  init() {
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
  }

  var body: some Scene {
    mainWindow
  }
}

// MARK: - Scenes

extension DevaultApp {

  private var mainWindow: some Scene {
    WindowGroup {
      DevaultRootView(store: store)
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(
      width: WindowLayoutMetrics.windowDefaultWidth,
      height: WindowLayoutMetrics.windowDefaultHeight
    )
  }
}

// MARK: - Root View

private struct DevaultRootView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    AppView(store: store)
      // 컬럼 하한의 합에서 파생된다 (`WindowLayoutMetrics`). 컬럼 폭을 바꾸면 창도 함께 따라온다.
      .frame(
        minWidth: WindowLayoutMetrics.windowMinWidth,
        maxWidth: .infinity,
        minHeight: WindowLayoutMetrics.windowMinHeight,
        maxHeight: .infinity
      )
      .background(
        WindowCaptureBlocker(
          isEnabled: store.isWindowCaptureBlockingEnabled
        )
      )
  }
}
