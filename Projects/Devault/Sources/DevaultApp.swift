import SwiftUI
import UserNotifications

import ComposableArchitecture
import DVPresentation

@main
struct DevaultApp: App {

  /// ViewBuilder 안에서 만들면 body가 재평가될 때마다 Store가 새로 생성되어 상태가 날아간다.
  /// Debug 메뉴도 같은 Store를 참조해야 하므로 프로퍼티로 올린다.
  private let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  init() {
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
  }

  var body: some Scene {
    #if DEBUG
    mainWindow.commands { DevaultDebugCommands(store: store) }
    #else
    mainWindow
    #endif

    settingsWindow
  }
}

// MARK: - Scenes

extension DevaultApp {

  private var mainWindow: some Scene {
    WindowGroup {
      AppView(store: store)
        // minWidth: 사이드바(200) + SelectSecretType 그리드 요구 너비(약 700)를 담을 수 있는 하한.
        // 이보다 좁아지면 그리드 열이 찌그러져 카드가 겹친다.
        .frame(
          minWidth: 920,
          maxWidth: .infinity,
          minHeight: 600,
          maxHeight: .infinity
        )
        .background(WindowCaptureBlocker())
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 960, height: 700)
  }

  private var settingsWindow: some Scene {
    WindowGroup("Settings", id: "settings") {
      Text("Settings")
        .frame(width: 500, height: 400)
        .background(WindowCaptureBlocker())
    }
    .defaultSize(width: 500, height: 400)
  }
}
