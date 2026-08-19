// Copyright © 2026 Devault. All rights reserved

/// 민감 작업 전 사용자 인증과 반복 실패 감지를 수행합니다.
public protocol AuthenticateUseCase: Sendable {
    /// 로컬 인증(생체인증·PIN 등)을 요청한다. 인증이 일어나는 모든 곳(잠금 해제, Secret reveal 등)이
    /// 반드시 이 UseCase를 거쳐야 한다 — 짧은 시간 안에 반복 실패하면 비정상 접근으로 알리는 정책 사용.
    /// 인증 자체의 성공/실패 결과(throw 여부)는 그대로 호출부에 전달된다.
    /// - Parameter reason: 인증 요청 사유. 시스템 시트에 보일 문장은 하위 서비스가 만든다.
    func authenticate(reason: AuthenticationReason) async throws
}
