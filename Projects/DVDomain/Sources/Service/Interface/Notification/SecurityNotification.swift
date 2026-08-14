// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 로컬 알림으로 사용자에게 전달할 보안 이벤트입니다.
public enum SecurityNotification: Equatable, Sendable {
    /// 잠금 해제 반복 실패 등 비정상적인 접근이 감지됨. 문구는 소비처(Presentation)가 만드므로 여기선 원인 판단에 필요한 값만 들고 있는다.
    case abnormalAccess(kind: AbnormalAccessKind, threshold: Int)
    /// 클립보드에 민감 값이 30초 이상 남아 있어 정리함
    case clipboardExceeded(seconds: Int)
    /// Secret이 곧 만료됨. 인증 없이 노출될 수 있어 name은 포함하지 않음.
    case secretExpiresSoon(secretID: UUID, daysBefore: Int)
}

/// `abnormalAccess`를 유발한 반복 행위의 종류입니다. 문구는 소비처가 만들고, 여기선 분기 값만 제공합니다.
public enum AbnormalAccessKind: Equatable, Sendable {
    case authenticationFailure
    case repeatedCopy
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
