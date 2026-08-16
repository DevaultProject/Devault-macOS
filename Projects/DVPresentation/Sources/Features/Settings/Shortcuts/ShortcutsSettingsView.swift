// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

// MARK: - AppShortcut

private struct AppShortcut: Identifiable {
  var id: String { keys }
  let keys: String
  let title: String

  // TODO: - 현재는 임시 값, 추후 Feature/Client 연결 예정
  static let all: [AppShortcut] = [
    AppShortcut(keys: "⌘N", title: String.module("New Secret")),
    AppShortcut(keys: "⌘,", title: String.module("Open Settings")),
  ]
}

struct ShortcutsSettingsView: View {
  var body: some View {
    content
  }
}

// MARK: - Subviews

extension ShortcutsSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("Shortcuts")) {
      SettingsSection(title: String.module("App Shortcuts")) {
        ForEach(AppShortcut.all) { shortcut in
          SettingsValueRow(
            title: shortcut.title,
            value: shortcut.keys,
            valueStyle: .emphasized
          )
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("Shortcuts") {
  SettingsDetailPreview {
    ShortcutsSettingsView()
  }
}
