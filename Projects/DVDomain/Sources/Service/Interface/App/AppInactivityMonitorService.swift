// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 현재 앱과 마지막으로 상호작용한 이후의 경과 시간(초)을 제공한다.
public protocol AppInactivityMonitorService: Sendable {
  func inactivitySecondsStream() -> AsyncStream<TimeInterval>
}
