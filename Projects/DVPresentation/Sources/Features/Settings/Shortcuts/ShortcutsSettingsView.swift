// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

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
        // App 메뉴와 동일한 단일 소스(`AppMenuCommand`)에서 제목·단축키를 그대로 노출한다.
        ForEach(AppMenuCommand.all, id: \.self) { command in
          SettingsValueRow(
            title: command.title,
            value: command.displayKeys,
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
