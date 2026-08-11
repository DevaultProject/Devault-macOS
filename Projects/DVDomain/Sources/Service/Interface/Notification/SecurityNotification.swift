// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 로컬 알림으로 사용자에게 전달할 보안 이벤트입니다.
public enum SecurityNotification: Equatable, Sendable {
    /// 잠금 해제 반복 실패 등 비정상적인 접근이 감지됨
    case abnormalAccess(reason: String)
    /// 클립보드에 민감 값이 30초 이상 남아 있어 정리함
    case clipboardExceeded(seconds: Int)
    /// Secret이 곧 만료됨. 인증 없이 노출될 수 있어 name은 포함하지 않음.
    case secretExpiresSoon(secretID: UUID, daysBefore: Int)
}

/// 특정 시각에 발송되도록 예약하는 알림 요청입니다.
public struct ScheduledSecurityNotification: Equatable, Sendable {
    public let identifier: String
    public let notification: SecurityNotification
    public let fireDate: Date

    public init(identifier: String, notification: SecurityNotification, fireDate: Date) {
        self.identifier = identifier
        self.notification = notification
        self.fireDate = fireDate
    }
}
