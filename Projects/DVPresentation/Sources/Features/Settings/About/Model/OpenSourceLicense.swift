// Copyright © 2026 Devault. All rights reserved

import Foundation

// MARK: - OpenSourceLicense

/// About에 노출하는 서드파티 오픈소스 라이선스. 전문은 모듈 번들의 텍스트 리소스에서 로드한다.
enum OpenSourceLicense: CaseIterable, Hashable {
  case composableArchitecture
  case lottie

  /// 화면에 노출되는 순서.
  static let all: [OpenSourceLicense] = allCases

  var name: String {
    switch self {
    case .composableArchitecture: "ComposableArchitecture"
    case .lottie:                 "Lottie"
    }
  }

  var licenseName: String {
    switch self {
    case .composableArchitecture: "MIT"
    case .lottie:                 "Apache 2.0"
    }
  }

  /// 라이선스 전문. 번들 리소스에서 읽어오며, 실패 시 빈 문자열.
  var text: String {
    guard
      let url = Bundle.module.url(forResource: resourceName, withExtension: "txt"),
      let content = try? String(contentsOf: url, encoding: .utf8)
    else {
      return ""
    }
    return content
  }

  private var resourceName: String {
    switch self {
    case .composableArchitecture: "ComposableArchitecture-LICENSE"
    case .lottie:                 "Lottie-LICENSE"
    }
  }
}
