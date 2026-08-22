// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain
import DVPresentation

/// Composition Root 전체에서 공유하는 UseCase 인스턴스.
enum LiveUseCases {
    /// 화면을 넘나드는 인증 실패를 하나의 `AbnormalAccessMonitor`로 감지하기 위해 공유한다.
    /// 인증 시트 문구는 DVData가 접근 못 하는 로컬라이제이션 카탈로그 때문에
    /// `AuthenticationReason.moduleText(for:)`(DVPresentation)에서 만들어 주입한다.
    static let authenticate: any AuthenticateUseCase = AuthenticateUseCaseImpl(
        authenticationService: LocalUserAuthenticationServiceImpl(
            makeReason: AuthenticationReason.moduleText(for:)
        ),
        notificationService: LiveServices.securityNotification,
        settingsRepository: LiveRepositories.settings
    )

    /// `CopyToClipboardUseCase`는 반복 복사 감지의 `AbnormalAccessMonitor`가 화면마다 따로 생기면 카운터가 갈라진다.
    ///
    /// 반복 감지의 윈도·임계값은 여기서 정한다. 자동 정리의 시간·활성 여부는 설정 화면이 소유하므로
    /// 그쪽은 UseCase가 `SettingsRepository`에서 읽는다.
    static let copyToClipboard: any CopyToClipboardUseCase = CopyToClipboardUseCaseImpl(
        clipboardService: ClipboardServiceImpl(),
        notificationService: LiveServices.securityNotification,
        authenticateUseCase: authenticate,
        settingsRepository: LiveRepositories.settings,
        abnormalAccessWindow: .seconds(60),
        abnormalAccessThreshold: 5
    )

    /// `ScheduleSecretExpiryNotificationsUseCase`는 상태가 없어 공유가 필수는 아니지만,
    /// 설정 해석은 UseCase에 맡기고 Composition Root는 의존성 조립만 하도록 여기서 한 번만 만든다.
    static let expirySchedule: any ScheduleSecretExpiryNotificationsUseCase = ScheduleSecretExpiryNotificationsUseCaseImpl(
        repository: LiveRepositories.secret,
        notificationService: LiveServices.securityNotification,
        settingsRepository: LiveRepositories.settings
    )

    /// 게이트 판정의 단일 지점. 화면마다 만들면 판정이 갈리므로 여기서 한 번만 만든다.
    ///
    /// **등급은 아직 `.free`로 고정이다.** StoreKit(`PurchaseService`)이 붙으면 아래 두 클로저만 교체한다 — 판정 로직은 그대로 둔다.
    static let entitlement: any EntitlementUseCase = EntitlementUseCaseImpl(
        secretRepository: LiveRepositories.secret,
        projectRepository: LiveRepositories.project,
        entitlementProvider: { .free },
        entitlementStream: {
            // 값이 바뀔 일이 없으므로 현재값 하나만 방출하고 닫는다. 계약상 "구독 즉시 현재값 1회 방출"은 지켜진다.
            AsyncStream { continuation in
                continuation.yield(.free)
                continuation.finish()
            }
        }
    )
}
