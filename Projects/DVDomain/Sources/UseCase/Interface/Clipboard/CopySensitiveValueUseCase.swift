// Copyright © 2026 Devault. All rights reserved

/// 민감 값 복사와 클립보드 자동 비우기 정책을 수행합니다.
public protocol CopySensitiveValueUseCase: Sendable {
    /// 설정에 따라 사용자 인증 후 민감한 값을 클립보드에 복사한다. 일정 시간 후에도 그대로
    /// 남아 있으면 자동으로 정리하고, 짧은 시간 내 반복 복사는 비정상 접근으로 알린다.
    /// - Parameter value: 클립보드에 복사할 민감 값
    func execute(_ value: String) async throws
}
