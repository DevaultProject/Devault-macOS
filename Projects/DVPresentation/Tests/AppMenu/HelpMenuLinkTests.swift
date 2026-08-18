// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVPresentation

@Suite("HelpMenuLink")
struct HelpMenuLinkTests {

  @Test("all은 Help·Privacy Policy·Send Feedback 순서로 구성된다")
  func allContainsLinksInMenuOrder() {
    #expect(HelpMenuLink.all == [.help, .privacyPolicy, .sendFeedback])
  }

  @Test("Help는 지원 사이트로 연결된다")
  func helpURL() {
    #expect(HelpMenuLink.help.url.absoluteString == "https://devault-support.notion.site/")
  }

  @Test("Privacy Policy는 정책 사이트로 연결된다")
  func privacyPolicyURL() {
    #expect(HelpMenuLink.privacyPolicy.url.absoluteString == "https://devault-policy.notion.site/")
  }

  @Test("Send Feedback은 팀 이메일 mailto로 연결된다")
  func sendFeedbackURL() {
    #expect(HelpMenuLink.sendFeedback.url.absoluteString == "mailto:devault.devteam@gmail.com")
  }
}
