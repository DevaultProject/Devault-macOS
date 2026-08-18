// Copyright © 2026 Devault. All rights reserved

/// 로컬 보안 알림을 발송·예약·취소하는 서비스입니다.
public protocol SecurityNotificationService: Sendable {
    /// 알림 권한을 요청하고 허용 여부를 반환한다.
    func requestAuthorization() async throws -> Bool

    /// 알림을 즉시 발송한다.
    /// - Parameter notification: 발송할 알림 내용
    func notify(_ notification: SecurityNotification) async throws

    /// 지정된 시각에 발송되도록 알림을 예약한다.
    /// - Parameter request: 예약할 알림과 발송 시각
    func schedule(_ request: ScheduledSecurityNotification) async throws

    /// 예약된 알림을 식별자로 취소한다. 취소 자체는 실패하지 않는 연산이라 throws가 아니다.
    /// - Parameter identifiers: 취소할 알림 식별자 목록
    func cancel(identifiers: [String]) async

    /// 아직 발송되지 않은(pending) 예약 알림들의 식별자 목록을 반환한다.
    /// 원격 삭제 등으로 대상 Secret이 사라져 개별 취소가 불가능한 고아 알림을 걷어낼 때 쓴다.
    func pendingIdentifiers() async -> [String]
}
