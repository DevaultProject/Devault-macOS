// Copyright © 2026 Devault. All rights reserved

import SwiftUI

// MARK: - AppMenuCommand

/// macOS App 메뉴에 노출되는 전역 커맨드의 단일 소스.
///
/// 표시 문자열(`displayKeys`)과 실제 단축키(`keyboardShortcut`)가 같은 `key`/`modifiers`에서
/// 파생되므로, App 메뉴와 Shortcuts 설정 화면 사이에 값이 어긋날 수 없다.
enum AppMenuCommand: CaseIterable, Hashable {
  case newSecret
  case newProject
  case lockVault
  case openSettings

  /// 메뉴·설정 화면에 노출되는 순서.
  static let all: [AppMenuCommand] = AppMenuCommand.allCases

  // MARK: - Title

  var title: String {
    switch self {
    case .newSecret:    .module("New Secret")
    case .newProject:   .module("New Project")
    case .lockVault:    .module("Lock DeVault")
    case .openSettings: .module("Settings…")
    }
  }

  // MARK: - Shortcut

  var key: KeyEquivalent {
    switch self {
    case .newSecret:    "n"
    case .newProject:   "n"
    case .lockVault:    "l"
    case .openSettings: ","
    }
  }

  var modifiers: EventModifiers {
    switch self {
    case .newSecret:    .command
    case .newProject:   [.command, .shift]
    case .lockVault:    [.command, .control]
    case .openSettings: .command
    }
  }

  /// SwiftUI `.keyboardShortcut`에 그대로 넘길 값.
  var keyboardShortcut: KeyboardShortcut {
    KeyboardShortcut(key, modifiers: modifiers)
  }

  /// Shortcuts 설정 화면에 표시할 단축키 문자열. macOS 표기 순서(⌃⌥⇧⌘) + 키.
  var displayKeys: String {
    var result = ""
    if modifiers.contains(.control) { result += "⌃" }
    if modifiers.contains(.option)  { result += "⌥" }
    if modifiers.contains(.shift)   { result += "⇧" }
    if modifiers.contains(.command) { result += "⌘" }
    result += keyDisplay
    return result
  }

  private var keyDisplay: String {
    let character = key.character
    return character.isLetter ? character.uppercased() : String(character)
  }

  // MARK: - Action

  /// 메뉴 선택 시 store로 보낼 액션. 각 항목은 기존 UI와 동일한 진입점을 재사용한다.
  var action: AppFeature.Action {
    switch self {
    case .newSecret:    .main(.sidebar(.didTapAddButton))
    case .newProject:   .main(.sidebar(.didTapAddProject))
    case .lockVault:    .main(.didTapLock)
    case .openSettings: .main(.sidebar(.didTapSettings))
    }
  }
}
