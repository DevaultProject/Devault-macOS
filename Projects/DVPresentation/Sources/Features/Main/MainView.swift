// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - MainView

struct MainView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<MainFeature>

  // MARK: - Body

  var body: some View {
    content
      // `screen`으로 좁히지 않으면 목록·상세가 바뀔 때마다 화면 전체가 다시 페이드된다.
      .animation(MotionMetrics.transition, value: store.screen)
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
      // DEBUG에서만 띄운다. 릴리스에는 아직 띄울 페이월이 없어서(B2 미완) 시트를 열면 내용도 닫기 버튼도 없는 모달에 갇힌다. **B2가 올라오면 이 조건을 걷어낸다.**
      #if DEBUG
      .sheet(isPresented: $store.isPaywallPresented.sending(\.setPaywallPresented)) {
        DebugPaywallView()
      }
      #endif
      .overlay(alignment: .topTrailing) {
          lockButton
              .padding(16)
              .ignoresSafeArea(edges: .top)
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
      } else if let selectStore = store.scope(state: \.selectSecretType, action: \.selectSecretType) {
        SelectSecretTypeView(store: selectStore)
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
      .frame(minWidth: isCollapsed ? 0 : WindowLayoutMetrics.listMinWidth)
      .navigationSplitViewColumnWidth(
        min: 0,
        ideal: isCollapsed ? 0 : WindowLayoutMetrics.listIdealWidth,
        max: isCollapsed ? 0 : WindowLayoutMetrics.listMaxWidth
      )
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
    .animation(MotionMetrics.transition, value: store.secretDetail?.id)
    .navigationTitle("")
    // max는 주지 않는다 — 컬럼이 창을 채우지 못하면 윈도우 배경이 양옆에 드러난다.
    // 폼 폭 상한은 컬럼이 아니라 `SecretDetailView` 안의 `formMaxWidth()`가 담당한다.
    .navigationSplitViewColumnWidth(
      min: WindowLayoutMetrics.detailMinWidth,
      ideal: WindowLayoutMetrics.detailIdealWidth
    )
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
