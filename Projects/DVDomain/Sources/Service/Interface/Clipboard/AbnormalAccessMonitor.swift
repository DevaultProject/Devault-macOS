// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 짧은 시간 안에 반복되는 접근을 비정상으로 판단하는 슬라이딩 윈도 카운터입니다.
public final class AbnormalAccessMonitor: @unchecked Sendable {
    private let window: TimeInterval
    private let threshold: Int
    private let lock = NSLock()
    private var timestamps: [Date] = []

    /// - Parameters:
    ///   - window: 반복 여부를 판단할 시간 범위(초)
    ///   - threshold: 이 윈도 안에서 몇 번째 접근부터 비정상으로 볼지
    public init(window: TimeInterval, threshold: Int) {
        self.window = window
        self.threshold = threshold
    }

    /// 이번 접근 기록으로 윈도 내 횟수가 임계값에 도달했다면 `true`를 반환하고
    /// 내부 기록을 리셋한다(다음 알림까진 다시 threshold회가 필요 — 알림 스팸 방지).
    /// - Parameter date: 접근이 발생한 시각
    /// - Returns: 이번 기록으로 임계값에 도달했는지 여부
    @discardableResult
    public func recordAccess(at date: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        timestamps.removeAll { date.timeIntervalSince($0) > window }
        timestamps.append(date)

        guard timestamps.count >= threshold else { return false }
        timestamps.removeAll()
        return true
    }
}
