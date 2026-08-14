// Copyright © 2026 Devault. All rights reserved

import DVDomain

extension SecurityNotification {
  /// `SecurityNotificationServiceImpl`(DVData)에 주입하는 알림 문구 팩토리. DVData가 접근 못 하는 로컬라이제이션 카탈로그를 이 모듈에서 대신 룩업한다.
  @Sendable
  public static func moduleContent(for notification: SecurityNotification) -> (title: String, body: String) {
    switch notification {
    case .abnormalAccess(let kind, let threshold):
      let body: String
      switch kind {
      case .authenticationFailure:
        body = String.module("Authentication failed \(threshold) times in a short period")
      case .repeatedCopy:
        body = String.module("A value was copied \(threshold) times in a short period")
      }
      return (String.module("Abnormal access detected"), body)

    case .clipboardExceeded(let seconds):
      return (
        String.module("Clipboard cleared"),
        String.module("The copied value was cleared after being on the clipboard for over \(seconds) seconds.")
      )

    case .secretExpiresSoon(_, let daysBefore):
      return (
        String.module("A secret is expiring soon"),
        String.module("A saved secret will expire in \(daysBefore) days.")
      )
    }
  }
}
