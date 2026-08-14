// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

// MARK: - AppShortcut

private struct AppShortcut: Identifiable {
  let id = UUID()
  let keys: String
  let title: String

  /// 실제로 `.keyboardShortcut(...)`이 걸려 있는 항목만 나열한다 — 명세에 있던 검색(⌘F)·
  /// 값 복사(⌘C)는 아직 대응하는 기능(검색 UI, 단일 복사 대상)이 없어 뺐다. 전역 단축키
  /// (Quick Launcher/Lock Now)는 1차 배포 범위에서 제외.
  static let all: [AppShortcut] = [
    AppShortcut(keys: "⌘N", title: String.module("New Secret")),
    AppShortcut(keys: "⌘,", title: String.module("Open Settings")),
  ]
}

struct ShortcutsSettingsView: View {
  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("App Shortcuts")) {
        VStack(spacing: 0) {
          ForEach(AppShortcut.all) { shortcut in
            HStack {
              Text(shortcut.title)
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray900))
              Spacer()
              Text(shortcut.keys)
                .dvFont(.captionMDSemibold)
                .foregroundStyle(Color.dv(.gray600))
            }
            .padding(.vertical, 8)
          }
        }
      }
    }
  }
}
