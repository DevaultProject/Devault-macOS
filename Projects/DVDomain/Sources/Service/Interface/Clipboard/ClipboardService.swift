// Copyright © 2026 Devault. All rights reserved

/// 민감한 값을 클립보드에 복사하고, 방치되지 않도록 관리하는 서비스입니다.
public protocol ClipboardService: Sendable {
    /// 값을 클립보드에 복사한다. 일정 시간 후에도 그대로 남아 있으면 자동으로 정리하고,
    /// 짧은 시간 내 반복 복사는 비정상 접근으로 알린다.
    /// - Parameter value: 클립보드에 복사할 민감 값
    func copySensitiveValue(_ value: String) async throws
}
