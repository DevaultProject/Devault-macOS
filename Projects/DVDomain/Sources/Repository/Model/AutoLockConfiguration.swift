// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 앱 비활성 자동 잠금 설정입니다.
public struct AutoLockConfiguration: Equatable, Sendable {
    public let isEnabled: Bool
    public let timeout: Duration

    public init(isEnabled: Bool, timeout: Duration) {
        self.isEnabled = isEnabled
        self.timeout = timeout
    }
}
