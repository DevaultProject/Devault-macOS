// Copyright © 2026 Devault. All rights reserved

import Foundation
@preconcurrency import UserNotifications

import DVDomain

public struct SecurityNotificationServiceImpl: SecurityNotificationService {
    private let center: UNUserNotificationCenter
    private let makeContent: @Sendable (SecurityNotification) -> (title: String, body: String)

    /// `makeContent`는 Data 모듈에서 Presentation의 로컬라이제이션 카탈로그에 접근할 수 없어 외부에서 주입받는다.
    /// 이 타입이 직접 가질 수 없는 관심사를 순수 함수로 밖에서 받는다.
    public init(
        center: UNUserNotificationCenter = .current(),
        makeContent: @escaping @Sendable (SecurityNotification) -> (title: String, body: String)
    ) {
        self.center = center
        self.makeContent = makeContent
    }

    public func requestAuthorization() async throws -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            throw SecurityNotificationError.authorizationRequestFailed
        }
    }

    public func notify(_ notification: SecurityNotification) async throws {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: makeUNContent(for: notification),
            trigger: nil // trigger가 nil이면 즉시 발송
        )
        do {
            try await center.add(request)
        } catch {
            throw SecurityNotificationError.deliveryFailed
        }
    }

    public func schedule(_ request: ScheduledSecurityNotification) async throws {
        // UNTimeIntervalNotificationTrigger(지금으로부터 n초 후)가 아니라 절대 시각 기준
        // Calendar trigger를 쓴다 — fireDate 자체가 절대 시각이라 상대 시간으로 환산할 필요가 없음
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: request.fireDate
            ),
            repeats: false
        )
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: makeUNContent(for: request.notification),
            trigger: trigger
        )
        do {
            try await center.add(notificationRequest)
        } catch {
            throw SecurityNotificationError.scheduleFailed
        }
    }

    public func cancel(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}

// MARK: - Private

private extension SecurityNotificationServiceImpl {
    func makeUNContent(for notification: SecurityNotification) -> UNMutableNotificationContent {
        let (title, body) = makeContent(notification)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}
