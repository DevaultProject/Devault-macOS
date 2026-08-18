// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 SecurityNotificationService 구현. 호출 인자를 기록만 한다.
/// 자동 정리 등 백그라운드 Task에서도 `notify`가 동시에 호출될 수 있어 `NSLock`으로 상태를 보호한다
/// (`FakeClipboardService`와 같은 이유). 보호하지 않으면 배열 동시 append로 크래시한다.
public final class FakeSecurityNotificationService: SecurityNotificationService, @unchecked Sendable {
    private let lock = NSLock()
    private var _authorizationResult = true
    private var _errorOnNotify: SecurityNotificationError?
    private var _errorOnSchedule: SecurityNotificationError?
    private var _notified: [SecurityNotification] = []
    private var _scheduled: [ScheduledSecurityNotification] = []
    private var _cancelledIdentifiers: [[String]] = []

    public var authorizationResult: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _authorizationResult }
        set { lock.lock(); defer { lock.unlock() }; _authorizationResult = newValue }
    }
    public var errorOnNotify: SecurityNotificationError? {
        get { lock.lock(); defer { lock.unlock() }; return _errorOnNotify }
        set { lock.lock(); defer { lock.unlock() }; _errorOnNotify = newValue }
    }
    public var errorOnSchedule: SecurityNotificationError? {
        get { lock.lock(); defer { lock.unlock() }; return _errorOnSchedule }
        set { lock.lock(); defer { lock.unlock() }; _errorOnSchedule = newValue }
    }
    public var notified: [SecurityNotification] {
        lock.lock(); defer { lock.unlock() }; return _notified
    }
    public var scheduled: [ScheduledSecurityNotification] {
        lock.lock(); defer { lock.unlock() }; return _scheduled
    }
    public var cancelledIdentifiers: [[String]] {
        lock.lock(); defer { lock.unlock() }; return _cancelledIdentifiers
    }

    public init() {}

    public func requestAuthorization() async -> Bool {
        lock.lock(); defer { lock.unlock() }; return _authorizationResult
    }

    public func notify(_ notification: SecurityNotification) async throws {
        lock.lock()
        defer { lock.unlock() }
        if let error = _errorOnNotify { throw error }
        _notified.append(notification)
    }

    public func schedule(_ request: ScheduledSecurityNotification) async throws {
        lock.lock()
        defer { lock.unlock() }
        if let error = _errorOnSchedule { throw error }
        _scheduled.append(request)
    }

    public func cancel(identifiers: [String]) async {
        lock.lock()
        defer { lock.unlock() }
        _cancelledIdentifiers.append(identifiers)
    }
}
