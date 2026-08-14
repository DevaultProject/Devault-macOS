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
        notificationService: LiveServices.securityNotification,
        isAlertEnabled: {
            let notificationUseCase: any NotificationSettingsUseCase = NotificationSettingsUseCaseImpl(
                repository: LiveRepositories.settings
            )
            return notificationUseCase.isAuthFailureAlertEnabled()
        }
    )

    /// `CopySensitiveValueUseCase`도 위와 같은 이유로 공유해야 한다 — 반복 복사 감지의
    /// `AbnormalAccessMonitor`가 화면마다 따로 생기면 카운터가 갈라진다.
    static let copySensitiveValue: any CopySensitiveValueUseCase = CopySensitiveValueUseCaseImpl(
        clipboardService: ClipboardServiceImpl(),
        notificationService: LiveServices.securityNotification,
        clipboardClearDelay: {
            let securityUseCase: any SecuritySettingsUseCase = SecuritySettingsUseCaseImpl(
                repository: LiveRepositories.settings
            )
            guard securityUseCase.isAutoClearClipboardEnabled() else { return nil }
            return .seconds(securityUseCase.autoClearClipboardDelaySeconds())
        },
        isAbnormalAccessAlertEnabled: {
            let notificationUseCase: any NotificationSettingsUseCase = NotificationSettingsUseCaseImpl(
                repository: LiveRepositories.settings
            )
            return notificationUseCase.isClipboardAbnormalAccessAlertEnabled()
        }
    )

    /// `ScheduleSecretExpiryNotificationsUseCase`는 상태가 없어 공유가 필수는 아니지만, 여러
    /// Client가 각자 설정 읽기 클로저를 중복 작성하지 않도록 여기서 한 번만 만든다.
    static let expirySchedule: any ScheduleSecretExpiryNotificationsUseCase = ScheduleSecretExpiryNotificationsUseCaseImpl(
        repository: LiveRepositories.secret,
        notificationService: LiveServices.securityNotification,
        isEnabled: {
            let notificationUseCase: any NotificationSettingsUseCase = NotificationSettingsUseCaseImpl(
                repository: LiveRepositories.settings
            )
            return notificationUseCase.isExpiryAlertsEnabled()
        },
        daysBeforeExpiry: {
            let notificationUseCase: any NotificationSettingsUseCase = NotificationSettingsUseCaseImpl(
                repository: LiveRepositories.settings
            )
            return notificationUseCase.expiryAlertDaysBefore()
        }
    )
}
