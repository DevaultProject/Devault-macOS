// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVPresentation

@Suite("OpenSourceLicense")
struct OpenSourceLicenseTests {

  @Test("all은 ComposableArchitecture와 Lottie를 순서대로 포함한다")
  func allContainsDependencies() {
    #expect(OpenSourceLicense.all == [.composableArchitecture, .lottie])
  }

  @Test("각 항목의 라이선스 전문이 번들에서 비어있지 않게 로드된다")
  func textLoadsNonEmpty() {
    for license in OpenSourceLicense.all {
      #expect(!license.text.isEmpty)
    }
  }

  @Test("ComposableArchitecture 전문에 MIT 저작권 표기가 포함된다")
  func tcaTextContainsCopyright() {
    #expect(OpenSourceLicense.composableArchitecture.text.contains("Point-Free"))
  }

  @Test("Lottie 전문에 Apache 저작권 표기가 포함된다")
  func lottieTextContainsCopyright() {
    #expect(OpenSourceLicense.lottie.text.contains("Airbnb"))
  }
}
