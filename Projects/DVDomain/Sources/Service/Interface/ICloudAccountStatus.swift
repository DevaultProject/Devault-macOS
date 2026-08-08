// Copyright © 2026 Devault. All rights reserved

/// iCloud 계정의 사용 가능 상태입니다.
public enum ICloudAccountStatus: Equatable, Sendable {
    /// 로그인되어 있고 정상적으로 사용 가능
    case available
    /// iCloud 계정이 로그인되어 있지 않음
    case noAccount
    /// 상위 관리 정책 등으로 사용이 제한됨
    case restricted
    /// 일시적으로 사용할 수 없음
    case temporarilyUnavailable
    /// 네트워크 문제로 상태 확인에 실패함
    case networkUnavailable
    /// 상태를 확인하지 못함
    case couldNotDetermine
}
