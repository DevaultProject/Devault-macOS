// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 ClipboardService 구현. 실제 NSPasteboard 대신 호출 인자를 기록만 한다.
/// 백그라운드 Task에서도 `clearIfUnchanged`가 호출될 수 있어 `NSLock`으로 상태를 보호한다.
public final class FakeClipboardService: ClipboardService, @unchecked Sendable {
    private let lock = NSLock()
    private var _changeCountToReturn = 1
    private var _errorOnWrite: ClipboardError?
    private var _clearIfUnchangedResult = true
    private var _writtenValues: [String] = []
    private var _clearIfUnchangedCalls: [Int] = []

    public var changeCountToReturn: Int {
        get { lock.lock(); defer { lock.unlock() }; return _changeCountToReturn }
        set { lock.lock(); defer { lock.unlock() }; _changeCountToReturn = newValue }
    }
    public var errorOnWrite: ClipboardError? {
        get { lock.lock(); defer { lock.unlock() }; return _errorOnWrite }
        set { lock.lock(); defer { lock.unlock() }; _errorOnWrite = newValue }
    }
    public var clearIfUnchangedResult: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _clearIfUnchangedResult }
        set { lock.lock(); defer { lock.unlock() }; _clearIfUnchangedResult = newValue }
    }
    public var writtenValues: [String] {
        lock.lock(); defer { lock.unlock() }; return _writtenValues
    }
    public var clearIfUnchangedCalls: [Int] {
        lock.lock(); defer { lock.unlock() }; return _clearIfUnchangedCalls
    }

    public init() {}

    public func write(_ value: String) throws -> Int {
        lock.lock()
        defer { lock.unlock() }
        if let error = _errorOnWrite { throw error }
        _writtenValues.append(value)
        return _changeCountToReturn
    }

    public func clearIfUnchanged(from changeCount: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        _clearIfUnchangedCalls.append(changeCount)
        return _clearIfUnchangedResult
    }
}
