// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 라벨 + 설명 + Button으로 구성된 설정 행. 앱 또는 시스템 동작에 사용.
struct SettingsButtonRow: View {
  let title: String
  let description: String?
  let buttonTitle: String
  let systemImage: String?
  let iconColor: Color?
  let action: () -> Void

  init(
    title: String,
    description: String? = nil,
    buttonTitle: String,
    systemImage: String? = nil,
    iconColor: Color? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.description = description
    self.buttonTitle = buttonTitle
    self.systemImage = systemImage
    self.iconColor = iconColor
    self.action = action
  }

  var body: some View {
    HStack(alignment: .center) {
      if let systemImage {
        Image(systemName: systemImage)
          .foregroundStyle(iconColor ?? Color.dv(.gray500))
          .accessibilityHidden(true)
      }
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
      Button(buttonTitle, action: action)
        .buttonStyle(.plain)
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
    }
    .settingsRowLayout()
  }
}

// MARK: - Preview

#Preview("Settings Button Row") {
  Form {
    Section {
      SettingsButtonRow(
        title: "Notifications are turned off",
        description: "System notification permission is required for these alerts to appear.",
        buttonTitle: "Open System Settings",
        systemImage: "bell.slash.fill",
        iconColor: Color.dv(.warning)
      ) {}
    }
  }
  .formStyle(.grouped)
  .scrollContentBackground(.hidden)
  .frame(width: WindowLayoutMetrics.settingsDetailWidth)
  .background(Color.dv(.gray100))
}
