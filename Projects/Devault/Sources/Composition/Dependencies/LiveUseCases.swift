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
}
