// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct MonitorAppInactivityUseCaseImpl: MonitorAppInactivityUseCase {
    private let service: any AppInactivityMonitorService
    private let repository: any SettingsRepository
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(
        service: any AppInactivityMonitorService,
        repository: any SettingsRepository,
        sleep: @escaping @Sendable (Duration) async throws -> Void = {
            try await ContinuousClock().sleep(for: $0)
        }
    ) {
        self.service = service
        self.repository = repository
        self.sleep = sleep
    }

    public func timeoutStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let scheduler = InactivityTimeoutScheduler(
                sleep: sleep,
                onTimeout: { continuation.yield(()) }
            )
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await _ in service.interactionStream() {
                            guard !Task.isCancelled else { break }
                            await scheduler.interactionDidOccur()
                        }
                    }
                    group.addTask {
                        for await configuration in repository.autoLockConfigurationStream() {
                            guard !Task.isCancelled else { break }
                            await scheduler.configurationDidChange(configuration)
                        }
                    }
                    await group.waitForAll()
                }

                await scheduler.cancel()
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private actor InactivityTimeoutScheduler {
    private let sleep: @Sendable (Duration) async throws -> Void
    private let onTimeout: @Sendable () -> Void
    private var configuration: AutoLockConfiguration?
    private var timeoutTask: Task<Void, Never>?

    init(
        sleep: @escaping @Sendable (Duration) async throws -> Void,
        onTimeout: @escaping @Sendable () -> Void
    ) {
        self.sleep = sleep
        self.onTimeout = onTimeout
    }

    func interactionDidOccur() {
        resetTimer()
    }

    func configurationDidChange(_ configuration: AutoLockConfiguration) {
        guard self.configuration != configuration else { return }
        self.configuration = configuration
        resetTimer()
    }

    func cancel() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    private func resetTimer() {
        timeoutTask?.cancel()
        timeoutTask = nil

        guard let configuration, configuration.isEnabled else { return }
        let sleep = self.sleep
        let onTimeout = self.onTimeout
        timeoutTask = Task {
            do {
                try await sleep(configuration.timeout)
                guard !Task.isCancelled else { return }
                onTimeout()
            } catch {
                // 상호작용이나 설정 변경으로 취소된 이전 타이머다.
            }
        }
    }
}
