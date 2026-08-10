// Copyright © 2026 Devault. All rights reserved

import UserNotifications

/// `UNUserNotificationCenter`는 delegate를 weak로 들고 있어
/// 다른 곳에서 계속 붙잡아두지 않으면 바로 해제돼 delegate가 nil이 되어버리므로 싱글턴으로 둠
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegate()

  private override init() {
    super.init()
  }

  /// 앱이 foreground(포그라운드)일 때도 배너/사운드를 보여준다.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
