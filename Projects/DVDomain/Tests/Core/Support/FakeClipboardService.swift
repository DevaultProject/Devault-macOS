// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// 테스트용 ClipboardService 구현. 실제 NSPasteboard 대신 호출 인자를 기록만 한다.
public final class FakeClipboardService: ClipboardService, @unchecked Sendable {
    public var changeCountToReturn = 1
    public var errorOnWrite: ClipboardError?
    public var clearIfUnchangedResult = true
    public private(set) var writtenValues: [String] = []
    public private(set) var clearIfUnchangedCalls: [Int] = []

    public init() {}

    public func write(_ value: String) throws -> Int {
        if let error = errorOnWrite { throw error }
        writtenValues.append(value)
        return changeCountToReturn
    }

    public func clearIfUnchanged(from changeCount: Int) -> Bool {
        clearIfUnchangedCalls.append(changeCount)
        return clearIfUnchangedResult
    }
}
