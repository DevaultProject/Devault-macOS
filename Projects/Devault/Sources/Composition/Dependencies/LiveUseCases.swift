// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain

/// Composition Root 전체에서 공유하는 UseCase 인스턴스.
/// `AuthenticateUseCase`는 인증이 일어나는 모든 지점(Lock 해제, Secret reveal, 온보딩 Touch ID 활성화 등)이
/// 같은 `AbnormalAccessMonitor`를 참조해야 화면을 넘나드는 실패도 하나의 카운터로 잡히므로,
/// 각 Client가 개별 인스턴스를 만들지 않고 이 공유 인스턴스를 써야 한다.
enum LiveUseCases {
    static let authenticate: any AuthenticateUseCase = AuthenticateUseCaseImpl(
        authenticationService: LocalUserAuthenticationServiceImpl(),
        notificationService: SecurityNotificationServiceImpl()
    )

    /// 클립보드 자동 정리 타이머와 반복 복사 카운터를 들고 있는 actor다.
    /// 개별 인스턴스를 만들면 화면을 넘나드는 반복 복사가 서로 다른 카운터로 흩어지고,
    /// 이전 화면이 예약한 30초 정리도 추적되지 않는다. `authenticate`와 같은 이유로 공유한다.
    static let copySensitiveValue: any CopySensitiveValueUseCase = CopySensitiveValueUseCaseImpl(
        clipboardService: ClipboardServiceImpl(),
        notificationService: SecurityNotificationServiceImpl()
    )
}
