// Copyright © 2026 Devault. All rights reserved

import Foundation

// MARK: - HelpMenuLink

/// macOS Help 메뉴에 노출되는 외부 링크의 단일 소스.
///
/// store 액션이 아니라 외부 URL을 여는 항목이라 ``AppMenuCommand``와 분리한다.
/// (온보딩·잠금 화면에서도 항상 열 수 있어야 하므로 활성 조건도 없다.)
enum HelpMenuLink: CaseIterable, Hashable {
  case help
  case termsOfService
  case privacyPolicy
  case sendFeedback

  /// 메뉴에 노출되는 순서.
  static let all: [HelpMenuLink] = HelpMenuLink.allCases

  var title: String {
    switch self {
    case .help:          .module("DeVault Help")
    case .termsOfService: .module("Terms of Service")
    case .privacyPolicy: .module("Privacy Policy")
    case .sendFeedback:  .module("Send Feedback")
    }
  }

  var url: URL {
    switch self {
    case .help:          URL(string: "https://devault-devteam.notion.site/")!
    case .termsOfService: URL(string: "https://devault-devteam.notion.site/terms-of-service")!
    case .privacyPolicy: URL(string: "https://devault-devteam.notion.site/privacy-policy")!
    case .sendFeedback:  URL(string: "mailto:devault.devteam@gmail.com")!
    }
  }
}
