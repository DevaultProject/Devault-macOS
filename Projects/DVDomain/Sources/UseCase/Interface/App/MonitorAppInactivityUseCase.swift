// Copyright © 2026 Devault. All rights reserved

/// 앱 비활성 시간이 설정된 자동 잠금 기준에 도달했는지 감시합니다.
public protocol MonitorAppInactivityUseCase: Sendable {
  /// 자동 잠금 기준에 도달할 때마다 이벤트를 방출한다.
  /// - Returns: 자동 잠금 타임아웃 이벤트 스트림
  func timeoutStream() -> AsyncStream<Void>
}
