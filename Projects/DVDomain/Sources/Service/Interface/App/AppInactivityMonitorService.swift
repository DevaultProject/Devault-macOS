// Copyright © 2026 Devault. All rights reserved

/// 현재 앱에서 발생한 사용자 상호작용을 감시합니다.
public protocol AppInactivityMonitorService: Sendable {
  /// 키보드·마우스 등 앱 상호작용이 발생할 때 이벤트를 방출한다.
  /// - Returns: 앱 상호작용 이벤트 스트림
  func interactionStream() -> AsyncStream<Void>
}
