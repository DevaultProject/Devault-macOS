// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 서드파티 오픈소스 라이선스 전문을 스크롤로 보여주는 sheet 화면.
struct OpenSourceLicensesView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          ForEach(OpenSourceLicense.all, id: \.self) { license in
            VStack(alignment: .leading, spacing: 8) {
              Text(license.name)
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray900))
              Text(license.licenseName)
                .dvFont(.captionMDRegular)
                .foregroundStyle(Color.dv(.gray600))
              Text(license.text)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Color.dv(.gray900))
                .textSelection(.enabled)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(24)
      }
      .navigationTitle(String.module("Open Source Licenses"))
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(String.module("Done")) { dismiss() }
        }
      }
    }
    .frame(minWidth: 560, minHeight: 450)
  }
}

// MARK: - Preview

#Preview("Open Source Licenses") {
  OpenSourceLicensesView()
}
