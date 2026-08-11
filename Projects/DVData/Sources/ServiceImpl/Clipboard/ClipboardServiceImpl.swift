// Copyright © 2026 Devault. All rights reserved

import AppKit

import DVDomain

public struct ClipboardServiceImpl: ClipboardService {
    public init() {}

    public func write(_ value: String) throws -> Int {
        let pasteboard = NSPasteboard.general
        // clearContents()가 pasteboard 소유권을 이 프로세스로 가져오면서 changeCount를 증가
        // 이후 changeCount를 그대로 반환해두면, 호출부가 나중에 이 값이 바뀌었는지만 비교해서 "그 사이 다른 값이 복사됐는지" 판단 가능
        pasteboard.clearContents()
        guard pasteboard.setString(value, forType: .string) else {
            throw ClipboardError.writeFailed
        }
        return pasteboard.changeCount
    }

    /// NSPasteboard엔 compare-and-swap API가 없어 changeCount 비교와 clearContents()를 원자적으로 묶을 수 없다 — 이론적 TOCTOU는 감수한다.
    public func clearIfUnchanged(from changeCount: Int) -> Bool {
        // changeCount가 그대로면 그 사이 아무도 pasteboard를 건드리지 않았다는 뜻 — 안전하게 정리 가능
        // 바뀌었다면 사용자가 이미 다른 값을 복사한 것이므로 건드리지 않음
        guard NSPasteboard.general.changeCount == changeCount else { return false }
        NSPasteboard.general.clearContents()
        return true
    }
}
