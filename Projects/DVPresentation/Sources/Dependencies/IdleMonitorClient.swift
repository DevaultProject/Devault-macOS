// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

/// 시스템 유휴 시간(초)을 주기적으로 스트리밍하는 Client. 자동 잠금 타이머에 사용.
@DependencyClient
public struct IdleMonitorClient: Sendable {
  public var idleSecondsStream: @Sendable () -> AsyncStream<TimeInterval> = { AsyncStream { $0.finish() } }
}

extension IdleMonitorClient: TestDependencyKey {
  public static let testValue = IdleMonitorClient()

  public static let previewValue = IdleMonitorClient(
    idleSecondsStream: { AsyncStream { $0.finish() } }
  )
}

extension DependencyValues {
  public var idleMonitorClient: IdleMonitorClient {
    get { self[IdleMonitorClient.self] }
    set { self[IdleMonitorClient.self] = newValue }
  }
}
