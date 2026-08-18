// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret 만료 알림의 예약 상태를 동기화합니다.
public protocol ScheduleSecretExpiryNotificationsUseCase: Sendable {
    /// 만료일이 있는 모든 Secret의 알림을 다시 계산해 예약한다. 앱 시작 시 1회 호출.
    func syncAll() async throws

    /// 특정 Secret의 만료 알림을 현재 상태에 맞게 다시 맞춘다(생성·복원·수정 시 호출).
    ///
    /// **이전 예약을 먼저 전부 취소하고 다시 예약한다.** 만료일이 바뀌었으면 옛 마크가 남지 않고,
    /// 만료일이 지워졌으면(`expiresAt == nil`) 취소만 하고 끝난다. 호출부가 만료일 유무를 보고
    /// `cancel`과 갈라 부를 필요가 없다.
    /// - Parameter secret: 알림을 맞출 Secret
    func schedule(secret: Secret) async

    /// 특정 Secret의 예약된 만료 알림을 모두 취소한다(삭제 시 호출).
    /// - Parameter secretID: 알림을 취소할 Secret의 ID
    func cancel(secretID: UUID) async

    /// 예약된 **모든** 만료 알림을 취소한다(전체 데이터 삭제 시 호출).
    ///
    /// 개별 `cancel(secretID:)`와 달리 취소 대상 ID를 몰라도 되며, pending 목록에서
    /// 만료 알림 식별자를 찾아 일괄 취소한다.
    func cancelAll() async
}
