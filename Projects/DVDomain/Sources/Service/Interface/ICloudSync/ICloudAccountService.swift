// Copyright © 2026 Devault. All rights reserved

/// 현재 기기의 iCloud 계정 상태를 확인하는 서비스입니다.
public protocol ICloudAccountService: Sendable {
    /// iCloud 계정 로그인 및 사용 가능 여부를 확인한다.
    func fetchAccountStatus() async -> ICloudAccountStatus
}
