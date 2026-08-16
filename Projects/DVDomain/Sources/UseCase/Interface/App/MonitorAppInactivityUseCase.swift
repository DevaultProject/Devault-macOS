// Copyright © 2026 Devault. All rights reserved

public protocol MonitorAppInactivityUseCase: Sendable {
  func timeoutStream() -> AsyncStream<Void>
}
