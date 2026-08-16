// Copyright © 2026 Devault. All rights reserved

/// 값을 클립보드에 복사하고, 정책이 정한 만큼의 보안 처리를 함께 수행합니다.
public protocol CopyToClipboardUseCase: Sendable {
    /// 값을 클립보드에 복사한다. 인증·자동 정리·반복 복사 감지는 `policy`가 참여를 허용하고
    /// 설정도 켜져 있을 때만 수행한다.
    /// - Parameters:
    ///   - value: 클립보드에 복사할 값
    ///   - policy: 이 복사에 태울 정책
    func execute(_ value: String, policy: ClipboardCopyPolicy) async throws
}

public extension CopyToClipboardUseCase {
    /// 정책을 생략하면 `.sensitive`. 새 호출부가 빠뜨려도 안전한 쪽으로 떨어지도록 한 기본값이다.
    func execute(_ value: String) async throws {
        try await execute(value, policy: .sensitive)
    }
}
