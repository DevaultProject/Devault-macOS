// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol ScheduleSecretExpiryNotificationsUseCase: Sendable {
    /// 만료일이 있는 모든 Secret의 알림을 다시 계산해 예약한다. 앱 시작 시 1회 호출.
    func syncAll() async throws

    /// 특정 Secret의 만료 알림을 예약한다(생성/복원 시 호출).
    /// - Parameter secret: 알림을 예약할 Secret
    func schedule(secret: Secret) async

    /// 특정 Secret의 예약된 만료 알림을 모두 취소한다(삭제 시 호출).
    /// - Parameter secretID: 알림을 취소할 Secret의 ID
    func cancel(secretID: UUID) async
}
