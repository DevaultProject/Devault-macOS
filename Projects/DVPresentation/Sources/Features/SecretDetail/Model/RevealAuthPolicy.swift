// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - RevealAuthPolicy

/// 조회 화면에서 마스킹을 해제할 때 인증을 언제 다시 요구할지 정하는 정책.
///
/// 값으로 분리해 둔 이유는 **코드를 고치지 않고 동작을 바꾸기 위해서**다. 설정 화면이 생기면
/// 저장된 값으로 이 구조체를 만들어 주입하면 되고, Feature의 판정 로직은 그대로 둔다.
/// 테스트도 짧은 `ttl`을 주입해 만료 경로를 즉시 검증할 수 있다.
///
/// 창의 유효 범위는 **조회 중인 시크릿 하나**다. 다른 시크릿으로 옮기면 `SecretDetailFeature.State`가
/// 새로 할당되므로 창도 함께 사라진다 — 별도 무효화 처리가 필요 없다.
struct RevealAuthPolicy: Equatable, Sendable {

    /// 인증 성공 후 재인증 없이 reveal할 수 있는 시간.
    var ttl: TimeInterval

    /// 앱이 백그라운드로 가면 창을 닫을지.
    var invalidatesOnBackground: Bool

    /// 잠금 화면으로 돌아가면 창을 닫을지.
    ///
    /// 자동 잠금 기능이 아직 없어 현재는 발신되지 않는다. 기능이 생기면 이벤트만 붙이면 된다.
    var invalidatesOnLock: Bool

    /// 앱 기본값. 설정 화면이 생기기 전까지 이 값이 쓰인다.
    static let `default` = RevealAuthPolicy(
        ttl: 180,
        invalidatesOnBackground: true,
        invalidatesOnLock: true
    )

    /// 인증 시각과 현재 시각으로 창이 아직 열려 있는지 판정한다.
    /// - Parameters:
    ///   - authorizedAt: 마지막 인증 성공 시각. `nil`이면 인증한 적이 없다.
    ///   - now: 현재 시각.
    func isAuthorized(since authorizedAt: Date?, now: Date) -> Bool {
        guard let authorizedAt else { return false }
        return now.timeIntervalSince(authorizedAt) < ttl
    }

    /// 이 이벤트가 창을 닫아야 하는지.
    func invalidates(on event: AppLifecycleEvent) -> Bool {
        switch event {
        case .didEnterBackground: return invalidatesOnBackground
        case .didLock:            return invalidatesOnLock
        }
    }
}

// MARK: - Dependency

extension RevealAuthPolicy: DependencyKey {
    static let liveValue: RevealAuthPolicy = .default

    /// 테스트도 기본 정책으로 시작한다 — 만료·무시 동작을 볼 때만 직접 주입한다.
    static let testValue: RevealAuthPolicy = .default
}

extension DependencyValues {

    /// 조회 화면 reveal 인증 정책. 설정 화면이 생기면 이 주입 지점만 바꾼다.
    var revealAuthPolicy: RevealAuthPolicy {
        get { self[RevealAuthPolicy.self] }
        set { self[RevealAuthPolicy.self] = newValue }
    }
}
