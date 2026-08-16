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
    /// 사용자 인증이 짧은 시간 안에 반복해서 실패함
    case authenticationFailure
    /// 민감 값 복사가 짧은 시간 안에 반복됨
    case repeatedCopy
}

/// 특정 시각에 발송되도록 예약하는 알림 요청입니다.
public struct ScheduledSecurityNotification: Equatable, Sendable {
    /// 예약과 취소에 사용하는 고유 식별자
    public let identifier: String
    /// 발송할 보안 이벤트
    public let notification: SecurityNotification
    /// 알림을 발송할 시각
    public let fireDate: Date

    /// 예약 식별자, 보안 이벤트와 발송 시각으로 요청을 생성한다.
    /// - Parameters:
    ///   - identifier: 예약과 취소에 사용할 고유 식별자
    ///   - notification: 발송할 보안 이벤트
    ///   - fireDate: 알림을 발송할 시각
    public init(identifier: String, notification: SecurityNotification, fireDate: Date) {
        self.identifier = identifier
        self.notification = notification
        self.fireDate = fireDate
    }
}
