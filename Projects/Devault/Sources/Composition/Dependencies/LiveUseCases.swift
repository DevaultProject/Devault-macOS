// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain

/// Composition Root 전체에서 공유하는 UseCase 인스턴스.
enum LiveUseCases {
    /// 화면을 넘나드는 인증 실패를 하나의 `AbnormalAccessMonitor`로 감지하기 위해 공유한다.
    static let authenticate: any AuthenticateUseCase = AuthenticateUseCaseImpl(
        authenticationService: LocalUserAuthenticationServiceImpl(),
        notificationService: LiveServices.securityNotification,
        settingsRepository: LiveRepositories.settings
    )

    /// `CopySensitiveValueUseCase`는 반복 복사 감지의 `AbnormalAccessMonitor`가 화면마다 따로 생기면 카운터가 갈라진다.
    static let copySensitiveValue: any CopySensitiveValueUseCase = CopySensitiveValueUseCaseImpl(
        clipboardService: ClipboardServiceImpl(),
        notificationService: LiveServices.securityNotification,
        authenticateUseCase: authenticate,
        settingsRepository: LiveRepositories.settings
    )

    /// `ScheduleSecretExpiryNotificationsUseCase`는 상태가 없어 공유가 필수는 아니지만,
    /// 설정 해석은 UseCase에 맡기고 Composition Root는 의존성 조립만 하도록 여기서 한 번만 만든다.
    static let expirySchedule: any ScheduleSecretExpiryNotificationsUseCase = ScheduleSecretExpiryNotificationsUseCaseImpl(
        repository: LiveRepositories.secret,
        notificationService: LiveServices.securityNotification,
        settingsRepository: LiveRepositories.settings
    )
}
