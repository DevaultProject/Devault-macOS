// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 라벨 + 설명 + 토글로 구성된 설정 행. Settings 카테고리 화면 전반에서 재사용.
struct SettingsToggleRow: View {
  let title: String
  var description: String?
  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
        if let description {
          Text(description)
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.gray600))
        }
      }
      Spacer(minLength: 12)
      Toggle("", isOn: $isOn)
        .toggleStyle(.switch)
        .labelsHidden()
        .accessibilityLabel(title)
    }
    .settingsRowLayout()
  }
}

// MARK: - Preview

#Preview("Settings Toggle Row") {
  Form {
    Section {
      SettingsToggleRow(
        title: "Require authentication on app launch",
        description: "Authenticate before showing saved secrets.",
        isOn: .constant(true)
      )

      SettingsToggleRow(
        title: "Require authentication to copy secret",
        isOn: .constant(false)
      )
    }
  }
  .formStyle(.grouped)
  .scrollContentBackground(.hidden)
  .frame(width: WindowLayoutMetrics.settingsDetailWidth)
  .background(Color.dv(.gray100))
}
