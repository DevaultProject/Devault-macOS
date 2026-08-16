// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("CopySensitiveValueUseCaseImpl")
struct CopySensitiveValueUseCaseImplTests {
    private let fixedInstant = ContinuousClock.now

    @Test("값을 ClipboardService에 그대로 쓴다")
    func executeWritesValue() async throws {
        let clipboardService = FakeClipboardService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: FakeSecurityNotificationService(),
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
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
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
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
            settingsRepository: makeSettingsRepository(),
            now: { self.fixedInstant }
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

    @Test("비정상 접근 알림이 꺼져 있으면 threshold에 도달해도 알림을 보내지 않는다")
    func disabledAbnormalAccessAlertDoesNotNotify() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isClipboardAbnormalAccessAlertEnabled: false
            ),
            now: { self.fixedInstant }
        )

        for _ in 0..<5 {
            try await sut.execute("secret-value")
        }

        let abnormalAccessCount = notificationService.notified.filter {
            if case .abnormalAccess = $0 { return true }
            return false
        }.count
        #expect(abnormalAccessCount == 0)
    }

    @Test("설정된 시간 뒤 pasteboard가 그대로면 정리하고 clipboardExceeded 알림을 보낸다")
    func executeClearsAndNotifiesWhenUnchanged() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls == [clipboardService.changeCountToReturn])
        #expect(notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }

    @Test("클립보드 자동 비우기가 꺼져 있으면 정리를 예약하지 않는다")
    func executeSkipsAutoClearWhenDisabled() async throws {
        let clipboardService = FakeClipboardService()
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: false
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(clipboardService.clearIfUnchangedCalls.isEmpty)
    }

    @Test("그 사이 다른 값이 복사됐으면 정리와 알림을 모두 건너뛴다")
    func executeSkipsWhenPasteboardChanged() async throws {
        let clipboardService = FakeClipboardService()
        clipboardService.clearIfUnchangedResult = false
        let notificationService = FakeSecurityNotificationService()
        let sut = CopySensitiveValueUseCaseImpl(
            clipboardService: clipboardService,
            notificationService: notificationService,
            settingsRepository: makeSettingsRepository(
                isAutoClearClipboardEnabled: true,
                autoClearClipboardDelaySeconds: 15
            ),
            now: { self.fixedInstant },
            sleep: { _ in }
        )

        try await sut.execute("secret-value")
        try await Task.sleep(for: .milliseconds(100))

        #expect(!notificationService.notified.contains(.clipboardExceeded(seconds: 15)))
    }
}

extension CopySensitiveValueUseCaseImplTests {
    private func makeSettingsRepository(
        isAutoClearClipboardEnabled: Bool = false,
        autoClearClipboardDelaySeconds: Int = 30,
        isClipboardAbnormalAccessAlertEnabled: Bool = true
    ) -> FakeSettingsRepository {
        let repository = FakeSettingsRepository()
        repository.isAutoClearClipboardEnabledValue = isAutoClearClipboardEnabled
        repository.autoClearClipboardDelaySecondsValue = autoClearClipboardDelaySeconds
        repository.isClipboardAbnormalAccessAlertEnabledValue = isClipboardAbnormalAccessAlertEnabled
        return repository
    }
}
