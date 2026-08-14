// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// Settings 카테고리 화면 안의 그룹 헤더 + 내용 컨테이너.
struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
      VStack(alignment: .leading, spacing: 0) {
        content()
      }
    }
  }
}

/// Settings 카테고리 화면 최상위 스크롤 컨테이너. 섹션 간 공통 여백을 담당.
struct SettingsScrollContainer<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        content()
      }
      .padding(24)
      .frame(maxWidth: 560, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
  }
}
