// Copyright © 2026 Devault. All rights reserved

import Foundation

import DVCore

/// `UserAuthenticationService`(인증 실행)와 `SecurityNotificationService`(알림)를 조합해,
/// 짧은 시간 안에 인증 실패가 반복되면 비정상 접근으로 알리는 정책을 구현한다.
/// 반복 판단 로직 자체는 `AbnormalAccessMonitor`(순수·테스트 가능)에 위임한다.
///
/// Lock 화면뿐 아니라 Secret reveal 등 인증이 일어나는 모든 곳이 이 UseCase를 거치므로,
/// 화면을 넘나드는 실패도 하나의 카운터로 잡힌다(예: 여러 Secret의 reveal 인증을 연달아 실패).
/// 성공은 카운트를 되돌리지 않는다 — 슬라이딩 윈도가 시간이 지나면 자연히 오래된 실패를 밀어내므로 별도 리셋이 필요 없다.
public actor AuthenticateUseCaseImpl: AuthenticateUseCase {
    private static let abnormalAccessWindow: TimeInterval = 60
    private static let abnormalAccessThreshold = 5

    private let authenticationService: any UserAuthenticationService
    private let notificationService: any SecurityNotificationService
    private let now: @Sendable () -> Date
    private let abnormalAccessMonitor = AbnormalAccessMonitor(
        window: abnormalAccessWindow,
        threshold: abnormalAccessThreshold
    )

    public init(
        authenticationService: any UserAuthenticationService,
        notificationService: any SecurityNotificationService,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.authenticationService = authenticationService
        self.notificationService = notificationService
        self.now = now
    }

    public func authenticate(reason: String) async throws {
        do {
            try await authenticationService.authenticate(reason: reason)
        } catch {
            // 성공했다면 실패로 기록하지 않는다 — 인증 실패만 비정상 접근 신호로 본다.
            if abnormalAccessMonitor.recordAccess(at: now()) {
                do {
                    try await notificationService.notify(
                        .abnormalAccess(reason: "짧은 시간 안에 인증 실패가 \(Self.abnormalAccessThreshold)회 이상 반복됨")
                    )
                } catch {
                    Log.warn("비정상 접근 알림 발송 실패: \(error)", category: .notification)
                }
            }
            throw error
        }
    }
}
