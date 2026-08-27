// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
#if DEBUG
import AppKit
#endif

// MARK: - MainView

struct MainView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<MainFeature>

  // MARK: - Body

  var body: some View {
    content
      // `screen`으로 좁히지 않으면 목록·상세가 바뀔 때마다 화면 전체가 다시 페이드된다.
      .dvAnimation(MotionMetrics.transition, value: store.screen)
      .dvScreenBackground()
      .task { store.send(.task) }
      .sheet(
        item: $store.scope(state: \.createProject, action: \.createProject)
      ) { createProjectStore in
        CreateProjectView(store: createProjectStore)
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Spacer()
          lockButton
        }
      }
      .sheet(
        item: $store.scope(state: \.paywall, action: \.paywall)
      ) { paywallStore in
        DevaultProPaywallView(store: paywallStore)
      }
  }
}

// MARK: - Subviews

extension MainView {
    
  /// **`NavigationSplitView`는 하나뿐이다.** 생성 화면은 가운데 컬럼을 접어 2컬럼처럼 보이게 한다.
  ///
  /// 컬럼 수가 다른 두 `NavigationSplitView`는 타입이 달라 `if/else`로 교체하면 서브트리가 통째로
  /// 새로 만들어진다 — 사이드바까지 재생성되어 토글 버튼이 튀고 `.task`가 재실행돼 목록이 깜빡였다.
  @ViewBuilder
  private var content: some View {
    switch store.screen {
    case .settings:
      if let settingsStore = store.scope(state: \.settings, action: \.settings) {
        SettingsView(store: settingsStore)
          .transition(.opacity)
      }

    case .browsing, .creating:
      NavigationSplitView {
        sidebarColumn
      } content: {
        contentColumn
      } detail: {
        detailArea
      }
      .navigationSplitViewStyle(.balanced)
      .toolbarBackground(.hidden, for: .windowToolbar)
      .transition(.opacity)
    }
  }

  @ViewBuilder
  private var detailArea: some View {
    if store.screen == .creating {
      // 폼이 떠 있는 동안에도 타입 선택 State는 살아 있으므로 폼을 먼저 본다.
      if let createSecretStore = store.scope(state: \.createSecret, action: \.createSecret) {
        CreateSecretView(store: createSecretStore)
          #if DEBUG
          .columnWidthProbe("detail(form)", screen: store.screen)
          #endif
      } else if let selectStore = store.scope(state: \.selectSecretType, action: \.selectSecretType) {
        SelectSecretTypeView(store: selectStore)
          #if DEBUG
          .columnWidthProbe("detail(typeGrid)", screen: store.screen)
          #endif
      }
    } else {
      detailColumn
    }
  }

  /// 폭을 고정한다(min == ideal == max). 범위를 주면 `.balanced`가 남는 폭을 컬럼끼리 나눠 가져,
  /// 가운데가 접힐 때 사이드바 폭이 흔들린다.
  private var sidebarColumn: some View {
    SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
      .navigationSplitViewColumnWidth(
        min: WindowLayoutMetrics.sidebarWidth,
        ideal: WindowLayoutMetrics.sidebarWidth,
        max: WindowLayoutMetrics.sidebarWidth
      )
      #if DEBUG
      .columnWidthProbe("sidebar", screen: store.screen)
      #endif
  }

  /// 생성 중에는 폭 0으로 접혀 2컬럼처럼 보인다.
  ///
  /// 뷰를 없애거나 다른 modifier를 붙이면 뷰 타입이 달라져 위 주석의 재생성 문제가 돌아온다.
  /// 살려둔 채 **같은 modifier의 값만** 바꾼다.
  private var contentColumn: some View {
    let isCollapsed = store.screen == .creating
    return SecretListView(store: store.scope(state: \.secretList, action: \.secretList))
      .navigationTitle("")
      .opacity(isCollapsed ? 0 : 1)
      // 드래그 하한은 컬럼이 아니라 콘텐츠가 갖는다. 컬럼 `min`으로 주면 접힐 때
      // `width >= 300`과 `MaxSize <= 0`이 공존해 AppKit이 제약 충돌을 뱉는다.
      //
      // 접을 때는 상한도 0으로 눌러야 한다. 하한만 풀면 목록이 자기 콘텐츠 폭(행 `DVVaultContainer`의
      // `minWidth: 200`)을 계속 요구하고, 컬럼 `max: 0`보다 그쪽이 이기는 macOS에서 200pt 여백이 남는다.
      .frame(
        minWidth: isCollapsed ? 0 : WindowLayoutMetrics.listMinWidth,
        maxWidth: isCollapsed ? 0 : nil
      )
      .navigationSplitViewColumnWidth(
        min: 0,
        ideal: isCollapsed ? 0 : WindowLayoutMetrics.listIdealWidth,
        max: isCollapsed ? 0 : WindowLayoutMetrics.listMaxWidth
      )
      #if DEBUG
      .columnWidthProbe("content", screen: store.screen)
      #endif
  }

  private var detailColumn: some View {
    Group {
      if let detailStore = store.scope(state: \.secretDetail, action: \.secretDetail) {
        SecretDetailView(store: detailStore)
          .transition(.opacity)
      } else {
        Text(.module("No secret selected"))
          .dvFont(.captionLG)
          .foregroundStyle(Color.dv(.gray700))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.opacity)
      }
    }
    // id로 좁힌다. State 전체로 넓히면 조회 화면 안에서 필드를 열 때마다 상세가 다시 페이드된다.
    .dvAnimation(MotionMetrics.transition, value: store.secretDetail?.id)
    .navigationTitle("")
    // max는 주지 않는다 — 컬럼이 창을 채우지 못하면 윈도우 배경이 양옆에 드러난다.
    // 폼 폭 상한은 컬럼이 아니라 `SecretDetailView` 안의 `formMaxWidth()`가 담당한다.
    .navigationSplitViewColumnWidth(
      min: WindowLayoutMetrics.detailMinWidth,
      ideal: WindowLayoutMetrics.detailIdealWidth
    )
    #if DEBUG
    .columnWidthProbe("detail(browse)", screen: store.screen)
    #endif
  }

  /// 초록 토큰이 둘뿐이라 press는 색만으로 hover와 구분되지 않아 흐림을 함께 준다.
  private var lockButton: some View {
    DVIconButton(
      systemName: "lock",
      font: .headingLG,
      idle: .vaultGreen,
      hovered: .vaultGreenDark,
      pressed: .vaultGreenDark,
      pressedOpacity: 0.7,
      hitSize: 28
    ) {
      store.send(.didTapLock)
    }
    .accessibilityLabel(String.module("Lock App"))
  }
}

// MARK: - 임시 진단 프로브 (이슈 #131)

#if DEBUG

/// **임시 코드다. #131 원인이 잡히면 통째로 지운다.** 15인치 이상에서 생성 화면의 가운데 컬럼이 폭 0으로
/// 접히지 않는 현상을 발생 기기에서 실측하기 위한 로그다. 14인치(macOS 26.5.2)에서는 창 폭 1120~1710
/// 전 구간이 정확히 0으로 접혀 재현되지 않았으므로, 필요한 값은 **그 기기의 OS·화면·컬럼 실측 폭**이다.
///
/// Debug로 실행해 생성 화면에 들어간 뒤 콘솔에서 `COLPROBE`로 필터해 붙여 주면 된다.
extension View {

  func columnWidthProbe(_ label: String, screen: MainFeature.State.Screen) -> some View {
    background {
      GeometryReader { proxy in
        Color.clear
          .onChange(of: proxy.size.width, initial: true) { _, width in
            ColumnWidthProbeLog.environmentOnce()
            ColumnWidthProbeLog.column(label, screen: screen, width: width)
          }
      }
    }
  }
}

private enum ColumnWidthProbeLog {

  /// 기기·OS·화면. 재현 조건이 화면 크기인지 OS 버전인지를 이 줄로 가른다.
  static func environmentOnce() {
    guard !hasLoggedEnvironment else { return }
    hasLoggedEnvironment = true

    let screen = NSScreen.main
    let frame = screen?.frame ?? .zero
    let visible = screen?.visibleFrame ?? .zero
    print(
      "[COLPROBE] env model=\(hardwareModel) os=\(ProcessInfo.processInfo.operatingSystemVersionString)"
        + " screen=\(Int(frame.width))x\(Int(frame.height))"
        + " visible=\(Int(visible.width))x\(Int(visible.height))"
        + " scale=\(screen?.backingScaleFactor ?? 0)"
    )
  }

  static func column(_ label: String, screen: MainFeature.State.Screen, width: CGFloat) {
    let window = NSApplication.shared.windows.first { $0.isVisible && $0.contentView != nil }
    print(
      "[COLPROBE] \(label.padding(toLength: 16, withPad: " ", startingAt: 0))"
        + " screen=\(screen) width=\(String(format: "%7.1f", width))"
        + " window=\(String(format: "%7.1f", window?.frame.width ?? -1))"
        + " zoomed=\(window?.isZoomed ?? false)"
    )
  }

  private static var hasLoggedEnvironment = false

  /// `Mac15,3`처럼 기종을 식별한다 — 15인치 이상인지, Intel인지 구분하는 근거다.
  private static var hardwareModel: String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    guard size > 0 else { return "unknown" }
    var value = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &value, &size, nil, 0)
    return String(cString: value)
  }
}

#endif

// MARK: - Preview

#if DEBUG

#Preview {
  MainView(
    store: Store(initialState: MainFeature.State()) {
      MainFeature()
    }
  )
}

#endif
