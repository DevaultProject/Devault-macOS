// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

struct AboutSettingsView: View {

  private var version: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
  }

  private var build: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
  }

  var body: some View {
    SettingsScrollContainer {
      SettingsSection(title: String.module("Version")) {
        HStack {
          Text(.module("Devault"))
            .dvFont(.bodyLG)
            .foregroundStyle(Color.dv(.gray900))
          Spacer()
          Text("\(version) (\(build))")
            .dvFont(.captionMDRegular)
            .foregroundStyle(Color.dv(.gray600))
        }
        .padding(.vertical, 8)
      }

      SettingsSection(title: String.module("Developer")) {
        Text(.module("Devault Team"))
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
          .padding(.vertical, 8)
      }

      SettingsSection(title: String.module("License")) {
        Link(destination: URL(string: "https://github.com/DevaultProject/Devault-macOS/blob/develop/LICENSE")!) {
          Text(.module("MIT License"))
            .dvFont(.bodyLG)
            .foregroundStyle(Color.dv(.vaultGreen))
        }
        .padding(.vertical, 8)
      }
    }
  }
}
