import AppKit
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

  /// 트랜잭션 감시 Task. 앱이 사는 동안 유지해야 외부 갱신·환불·가족 공유 승인을 놓치지 않는다.
  private let transactionObserver: Task<Void, Never>

  #if DEBUG
  /// 결제 도메인 확인용 데모 페이월. 진짜 페이월(B2)이 아니다.
  @State private var isDebugPaywallPresented = false
  #endif

  init() {
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    // 단일 창 앱이라 창 탭이 불필요
    NSWindow.allowsAutomaticWindowTabbing = false
    // 화면이 아니라 앱 수명에 묶는다. Feature effect로 띄우면 화면이 사라질 때 리스너가 죽는다.
    transactionObserver = LiveServices.purchase.observeTransactionUpdates()
  }

  var body: some Scene {
    mainWindow
  }
}

// MARK: - Scenes

extension DevaultApp {

  private var mainWindow: some Scene {
    WindowGroup {
      debugPaywallHost {
        DevaultRootView(store: store)
      }
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(
      width: WindowLayoutMetrics.windowDefaultWidth,
      height: WindowLayoutMetrics.windowDefaultHeight
    )
    .commands {
      AppCommands(store: store)
      #if DEBUG
      DebugCommands(isPaywallPresented: $isDebugPaywallPresented)
      #endif
    }
  }
}

// MARK: - Debug Paywall

extension DevaultApp {

  /// 데모 페이월 시트를 얹는다. 릴리스 빌드에서는 내용을 그대로 통과시킨다.
  @ViewBuilder
  private func debugPaywallHost<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    #if DEBUG
    content().sheet(isPresented: $isDebugPaywallPresented) {
      DebugPaywallView()
    }
    #else
    content()
    #endif
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
      // nil이면 macOS 시스템 설정을 따르고, 그 외에는 앱 전체를 라이트/다크로 고정한다.
      .preferredColorScheme(store.appearance.colorScheme)
  }
}
