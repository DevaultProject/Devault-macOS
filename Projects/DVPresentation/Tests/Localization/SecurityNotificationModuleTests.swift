// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVDomain
import Testing

@testable import DVPresentation

@Suite("SecurityNotification module content")
struct SecurityNotificationModuleTests {
  @Test("만료 당일 알림은 오늘 만료 문구를 사용한다")
  func expirationDayContent() {
    let content = SecurityNotification.moduleContent(
      for: .secretExpiresSoon(secretID: UUID(), daysBefore: 0)
    )

    #expect(content.title == "A secret expires today")
    #expect(content.body == "A saved secret expires today.")
  }

  @Test("만료 전 알림은 남은 일수를 표시한다")
  func beforeExpirationContent() {
    let content = SecurityNotification.moduleContent(
      for: .secretExpiresSoon(secretID: UUID(), daysBefore: 7)
    )

    #expect(content.title == "A secret is expiring soon")
    #expect(content.body == "A saved secret will expire in 7 days.")
  }
}
