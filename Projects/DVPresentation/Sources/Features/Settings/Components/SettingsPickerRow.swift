// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 라벨 + 설명 + Picker로 구성된 설정 행. Settings 카테고리 화면 전반에서 재사용.
struct SettingsPickerRow<SelectionValue: Hashable, Options: View>: View {
  let title: String
  let description: String?
  @Binding var selection: SelectionValue
  @ViewBuilder let options: () -> Options

  init(
    title: String,
    description: String? = nil,
    selection: Binding<SelectionValue>,
    @ViewBuilder options: @escaping () -> Options
  ) {
    self.title = title
    self.description = description
    self._selection = selection
    self.options = options
  }

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
      Picker(title, selection: $selection) {
        options()
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .dvFont(.bodyMD)
      .foregroundStyle(Color.dv(.gray900))
    }
    .settingsRowLayout()
  }
}

// MARK: - Preview

private struct SettingsPickerRowPreview: View {
  @State private var selection = 5

  var body: some View {
    Form {
      Section {
        SettingsPickerRow(
          title: "Lock after inactivity",
          description: "Automatically locks DeVault when inactive.",
          selection: $selection
        ) {
          Text("1 min").tag(1)
          Text("5 min").tag(5)
          Text("15 min").tag(15)
        }
      }
    }
    .formStyle(.grouped)
    .scrollContentBackground(.hidden)
    .frame(width: WindowLayoutMetrics.settingsDetailWidth)
    .background(Color.dv(.gray100))
  }
}

#Preview("Settings Picker Row") {
  SettingsPickerRowPreview()
}
