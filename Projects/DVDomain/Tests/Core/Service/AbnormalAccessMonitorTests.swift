// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("AbnormalAccessMonitor")
struct AbnormalAccessMonitorTests {
    @Test("윈도 안에서 threshold 미만이면 false를 반환한다")
    func belowThreshold() {
        let sut = AbnormalAccessMonitor(window: .seconds(60), threshold: 5)
        let base = ContinuousClock.now

        for offset in 0..<4 {
            #expect(sut.recordAccess(at: base.advanced(by: .seconds(offset))) == false)
        }
    }

    @Test("윈도 안에서 threshold에 도달하면 true를 반환하고 리셋된다")
    func reachesThreshold() {
        let sut = AbnormalAccessMonitor(window: .seconds(60), threshold: 5)
        let base = ContinuousClock.now

        for offset in 0..<4 {
            #expect(sut.recordAccess(at: base.advanced(by: .seconds(offset))) == false)
        }
        #expect(sut.recordAccess(at: base.advanced(by: .seconds(4))) == true)

        // 리셋됐으므로 바로 다음 기록은 다시 false
        #expect(sut.recordAccess(at: base.advanced(by: .seconds(5))) == false)
    }

    @Test("윈도 밖으로 벗어난 오래된 기록은 카운트에서 제외된다")
    func expiresOldTimestamps() {
        let sut = AbnormalAccessMonitor(window: .seconds(60), threshold: 5)
        let base = ContinuousClock.now

        for offset in 0..<4 {
            #expect(sut.recordAccess(at: base.advanced(by: .seconds(offset))) == false)
        }
        // 4건 모두 윈도 밖으로 밀려난 시점 → 5번째 기록이어도 threshold 미달
        #expect(sut.recordAccess(at: base.advanced(by: .seconds(1_000))) == false)
    }
}
