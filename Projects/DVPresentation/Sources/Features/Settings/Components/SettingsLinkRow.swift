// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftUI

import DVDesign

/// 라벨 + 설명 + Link로 구성된 설정 행. 외부 URL 이동에 사용.
struct SettingsLinkRow: View {
  let title: String
  let description: String?
  let linkTitle: String
  let destination: URL

  init(
    title: String,
    description: String? = nil,
    linkTitle: String,
    destination: URL
  ) {
    self.title = title
    self.description = description
    self.linkTitle = linkTitle
    self.destination = destination
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
      Link(linkTitle, destination: destination)
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
    }
    .settingsRowLayout()
  }
}

// MARK: - Preview

#Preview("Settings Link Row") {
  Form {
    Section {
      if let destination = URL(string: "https://github.com") {
        SettingsLinkRow(
          title: "MIT License",
          linkTitle: "View on GitHub",
          destination: destination
        )
      }
    }
  }
  .formStyle(.grouped)
  .scrollContentBackground(.hidden)
  .frame(width: 656)
  .background(Color.dv(.gray100))
}
