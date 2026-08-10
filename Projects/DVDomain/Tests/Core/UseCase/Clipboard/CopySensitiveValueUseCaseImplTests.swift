// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CopySensitiveValueUseCaseImpl")
struct CopySensitiveValueUseCaseImplTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("값을 ClipboardService에 그대로 쓴다")
    func executeWritesValue() async throws {
        let clipboardService = FakeClipboardService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            now: { self.fixedDate }
        )

        try await sut.execute("secret-value")

        #expect(clipboardService.writtenValues == ["secret-value"])
    }

    @Test("write가 실패하면 그대로 throw한다")
    func executeThrowsOnWriteFailure() async {
        let clipboardService = FakeClipboardService()
        clipboardService.errorOnWrite = .writeFailed
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            now: { self.fixedDate }
        )

        await #expect(throws: ClipboardError.writeFailed) {
            try await sut.execute("secret-value")
        }
    }

    @Test("짧은 시간 안에 threshold회 복사하면 abnormalAccess 알림을 1회 보낸다")
    func executeNotifiesAbnormalAccessAtThreshold() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            now: { self.fixedDate }
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        let abnormalAccessCount = notificationService.notified.filter {
            if case .abnormalAccess = $0 { return true }
            return false
        }.count
        #expect(abnormalAccessCount == 1)
    }

    @Test("정해진 시간 뒤 pasteboard가 그대로면 정리하고 clipboardExceeded 알림을 보낸다")
    func executeClearsAndNotifiesWhenUnchanged() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            clipboardClearDelay: .milliseconds(10),
            now: { self.fixedDate }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls == [clipboardService.changeCountToReturn])
        // clipboardClearDelay가 10ms(=0초)이므로, 알림 문구도 하드코딩된 값이 아니라
        // 실제 delay에서 계산된 0초여야 한다(30초 리터럴이 남아있었다면 이 테스트가 실패했을 것).
        #expect(notificationService.notified.contains(.clipboardExceeded(seconds: 0)))
    }

    @Test("그 사이 다른 값이 복사됐으면(changeCount 변경) 정리·알림 모두 하지 않는다")
    func executeSkipsWhenPasteboardChanged() async throws {
        let clipboardService = FakeClipboardService()
        clipboardService.clearIfUnchangedResult = false
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            clipboardClearDelay: .milliseconds(10),
            now: { self.fixedDate }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(!notificationService.notified.contains(.clipboardExceeded(seconds: 0)))
    }
}
