// Copyright © 2026 Devault. All rights reserved

import Foundation
@preconcurrency import UserNotifications

import DVDomain

public struct SecurityNotificationServiceImpl: SecurityNotificationService {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
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
            content: Self.makeContent(for: notification),
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
            content: Self.makeContent(for: request.notification),
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
}

// MARK: - Private

private extension SecurityNotificationServiceImpl {
    static func makeContent(for notification: SecurityNotification) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        switch notification {
        case .abnormalAccess(let reason):
            content.title = "비정상 접근이 감지됐어요"
            content.body = reason

        case .clipboardExceeded(let seconds):
            content.title = "클립보드를 정리했어요"
            content.body = "복사된 값이 \(seconds)초 넘게 남아 있어 자동으로 지웠어요."

        case .secretExpiresSoon(_, let daysBefore):
            content.title = "Secret 만료가 다가와요"
            content.body = "저장된 Secret이 \(daysBefore)일 후 만료돼요."
        }
        content.sound = .default
        return content
    }
}
