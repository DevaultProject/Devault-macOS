// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// Settings 카테고리 화면에서 공통으로 사용하는 Form 섹션.
struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    Section {
      content()
    } header: {
      Text(title.uppercased())
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
    }
  }
}

/// 제목과 Section을 하나의 Form에서 함께 스크롤하는 Settings detail 컨테이너.
struct SettingsDetailContainer<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text(title)
          .dvFont(.headingXL)
          .foregroundStyle(Color.dv(.gray900))
          .padding(.horizontal, 20)

        Form {
          content()
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins([.horizontal, .top], 0, for: .scrollContent)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

/// Form 행의 콘텐츠를 leading으로 정렬하는 공통 규칙.
extension View {
  func settingsRowLayout() -> some View {
    frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// 실제 Settings detail 크기로 카테고리 뷰를 확인하는 Preview 컨테이너.
struct SettingsDetailPreview<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
    .frame(width: 656, height: 560, alignment: .topLeading)
    .dvScreenBackground()
  }
}

// MARK: - Preview

#Preview("Settings Section") {
  Form {
    SettingsSection(title: "Authentication") {
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
  .frame(width: 656)
  .background(Color.dv(.gray100))
}
