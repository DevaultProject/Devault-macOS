// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture

// MARK: - AppCommands

/// macOS App 메뉴에 전역 커맨드를 얹는다.
///
/// 항목은 ``AppMenuCommand`` 카탈로그에서 나오며, `main` 세션이 활성일 때만 활성화된다
/// (온보딩·잠금 화면에서는 비활성).
public struct AppCommands: Commands {
  private let store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  public var body: some Commands {
    // File ▸ New Secret(⌘N, 그리드) / New ▸(타입별 직접 생성) / New Project
    CommandGroup(replacing: .newItem) {
      button(for: .newSecret)
      newSecretTypeMenu
      button(for: .newProject)
    }

    // File ▸ Lock DeVault (New 그룹 아래 별도 섹션)
    CommandGroup(after: .newItem) {
      button(for: .lockVault)
    }

    // DeVault ▸ Settings…
    CommandGroup(replacing: .appSettings) {
      button(for: .openSettings)
    }

    // Help ▸ 지원·개인정보처리방침·피드백 (기본 도움말 항목 대체)
    CommandGroup(replacing: .help) {
      ForEach(HelpMenuLink.all, id: \.self) { link in
        Link(link.title, destination: link.url)
      }
    }

    // View ▸ Show/Hide Sidebar (⌃⌘S). NavigationSplitView와 자동 연동.
    SidebarCommands()

    // View ▸ Filters (사이드바 필터를 ⌘1–⌘5로 선택)
    CommandGroup(after: .sidebar) {
      filtersMenu
    }
  }

}

// MARK: - Menu Items

extension AppCommands {

  private func button(for command: AppMenuCommand) -> some View {
    Button(command.title) {
      store.send(command.action)
    }
    .keyboardShortcut(command.keyboardShortcut)
    // main 세션이 아닐 때(온보딩·잠금)는 트리거할 대상이 없으므로 비활성화한다.
    .disabled(store.main == nil)
  }

  /// File ▸ New ▸ — 타입 선택 그리드를 건너뛰고 6개 타입으로 바로 생성한다.
  private var newSecretTypeMenu: some View {
    Menu(String.module("New")) {
      ForEach(CreatableSecretType.allCases, id: \.self) { type in
        Button {
          store.send(.main(.createSecretRequested(type)))
        } label: {
          Label { Text(type.displayName) } icon: { type.icon }
        }
      }
    }
    .disabled(store.main == nil)
  }

  /// View ▸ Filters ▸ — 사이드바 필터를 메뉴에서 선택. 라벨은 사이드바와 동일 소스(`filter.title`).
  private var filtersMenu: some View {
    Menu(String.module("Filters")) {
      ForEach(Array(SidebarFilter.allCases.enumerated()), id: \.element) { index, filter in
        Button {
          store.send(.main(.sidebar(.didSelect(.filter(filter)))))
        } label: {
          Label(filter.title, systemImage: filter.icon)
        }
        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
      }
    }
    .disabled(store.main == nil)
  }
}
