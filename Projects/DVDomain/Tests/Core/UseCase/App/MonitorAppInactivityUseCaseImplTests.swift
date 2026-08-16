// Copyright © 2026 Devault. All rights reserved

import Testing

@testable import DVDomain

@Suite("MonitorAppInactivityUseCaseImpl")
struct MonitorAppInactivityUseCaseImplTests {
    @Test("자동 잠금이 켜져 있으면 설정 시간으로 단일 타이머를 예약한다")
    func schedulesTimeoutWhenEnabled() async {
        let repository = FakeSettingsRepository()
        repository.isAutoLockEnabledValue = true
        repository.autoLockMinutesValue = 5
        let recordedDuration = RecordedDuration()
        let sut = MonitorAppInactivityUseCaseImpl(
            service: FakeAppInactivityMonitorService(),
            repository: repository,
            sleep: { duration in await recordedDuration.set(duration) }
        )

        let didTimeout = await sut.timeoutStream().first { _ in true } != nil
        let duration = await recordedDuration.value

        #expect(didTimeout)
        #expect(duration == .seconds(300))
    }

    @Test("자동 잠금이 꺼져 있으면 타이머를 예약하지 않는다")
    func doesNotScheduleTimeoutWhenDisabled() async {
        let repository = FakeSettingsRepository()
        repository.isAutoLockEnabledValue = false
        let configurationPair = AsyncStream<AutoLockConfiguration>.makeStream()
        repository.autoLockConfigurationStreamValue = configurationPair.stream
        let interactionPair = AsyncStream<Void>.makeStream()
        let service = FakeAppInactivityMonitorService()
        service.interactionStreamValue = interactionPair.stream
        let sleepCount = InvocationCount()
        let sut = MonitorAppInactivityUseCaseImpl(
            service: service,
            repository: repository,
            sleep: { _ in await sleepCount.increment() }
        )
        let task = Task {
            for await _ in sut.timeoutStream() {}
        }

        configurationPair.continuation.yield(
            AutoLockConfiguration(isEnabled: false, timeout: .seconds(300))
        )
        configurationPair.continuation.finish()
        interactionPair.continuation.finish()
        await task.value
        let count = await sleepCount.value

        #expect(count == 0)
    }

    @Test("새 상호작용이 발생하면 기존 타이머를 취소하고 다시 예약한다")
    func interactionResetsTimeout() async {
        let interactionPair = AsyncStream<Void>.makeStream()
        let service = FakeAppInactivityMonitorService()
        service.interactionStreamValue = interactionPair.stream
        let repository = FakeSettingsRepository()
        repository.isAutoLockEnabledValue = true
        let sleepCount = InvocationCount()
        let sut = MonitorAppInactivityUseCaseImpl(
            service: service,
            repository: repository,
            sleep: { _ in
                await sleepCount.increment()
                try await Task.sleep(for: .seconds(10))
            }
        )
        let task = Task {
            for await _ in sut.timeoutStream() {}
        }

        await sleepCount.wait(until: 1)
        interactionPair.continuation.yield(())
        await sleepCount.wait(until: 2)
        task.cancel()
        interactionPair.continuation.finish()
        await task.value
        let count = await sleepCount.value

        #expect(count == 2)
    }
}

private actor RecordedDuration {
    private(set) var value: Duration?

    func set(_ value: Duration) {
        self.value = value
    }
}

private actor InvocationCount {
    private(set) var value = 0

    func increment() {
        value += 1
    }

    func wait(until expectedValue: Int) async {
        while value < expectedValue {
            await Task.yield()
        }
    }
}
