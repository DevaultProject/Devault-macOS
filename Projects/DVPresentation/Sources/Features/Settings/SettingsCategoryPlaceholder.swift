// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 아직 내용이 채워지지 않은 Settings 카테고리용 임시 화면.
struct SettingsCategoryPlaceholder: View {
  let title: String

  var body: some View {
    VStack(spacing: 8) {
      Text(title)
        .dvFont(.headingXL)
        .foregroundStyle(Color.dv(.gray900))
      Text(.module("Coming soon"))
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.gray600))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
