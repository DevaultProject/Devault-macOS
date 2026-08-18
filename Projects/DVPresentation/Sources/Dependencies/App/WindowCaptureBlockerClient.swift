// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

@DependencyClient
public struct WindowCaptureBlockerClient: Sendable {
  public var enabledStream: @Sendable () -> AsyncStream<Bool> = {
    AsyncStream { $0.finish() }
  }
}

extension WindowCaptureBlockerClient: TestDependencyKey {
  public static let testValue = WindowCaptureBlockerClient()
  public static let previewValue = WindowCaptureBlockerClient()
}

extension DependencyValues {
  public var windowCaptureBlockerClient: WindowCaptureBlockerClient {
    get { self[WindowCaptureBlockerClient.self] }
    set { self[WindowCaptureBlockerClient.self] = newValue }
  }
}
