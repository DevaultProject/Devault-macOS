// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 SecurityNotificationService 구현. 호출 인자를 기록만 한다.
public final class FakeSecurityNotificationService: SecurityNotificationService, @unchecked Sendable {
    public var authorizationResult = true
    public var errorOnNotify: SecurityNotificationError?
    public var errorOnSchedule: SecurityNotificationError?
    public private(set) var notified: [SecurityNotification] = []
    public private(set) var scheduled: [ScheduledSecurityNotification] = []
    public private(set) var cancelledIdentifiers: [[String]] = []

    public init() {}

    public func requestAuthorization() async -> Bool {
        authorizationResult
    }

    public func notify(_ notification: SecurityNotification) async throws {
        if let error = errorOnNotify { throw error }
        notified.append(notification)
    }

    public func schedule(_ request: ScheduledSecurityNotification) async throws {
        if let error = errorOnSchedule { throw error }
        scheduled.append(request)
    }

    public func cancel(identifiers: [String]) async {
        cancelledIdentifiers.append(identifiers)
    }
}
