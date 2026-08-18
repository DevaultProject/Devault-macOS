// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

/// Onboarding Feature 전용 Client. 보안(Touch ID)·iCloud 동기화 단계에서 사용.
/// Live 조립은 Devault(App 타겟)에서 인증·iCloud UseCase를 Client 인터페이스로 변환한다.
@DependencyClient
public struct OnboardingClient: Sendable {

    /// Touch ID 또는 시스템 암호로 사용자를 인증한다. 실패 시 `UserAuthenticationError`를 throw한다.
    public var enableTouchID: @Sendable () async throws -> Void

    /// iCloud 계정 상태를 확인하고, 사용 가능하면 동기화 사용 설정을 저장한다.
    public var enableICloudSync: @Sendable () async throws -> ICloudAccountStatus = { .couldNotDetermine }

    /// iCloud를 사용하지 않는 로컬 저장소 구성을 적용한다.
    public var continueWithoutICloud: @Sendable () async -> Void

    /// 시스템 설정 앱의 iCloud 패널을 연다. iCloud 계정 미로그인/제한 상태 알럿에서 사용.
    public var openICloudSystemSettings: @Sendable () async -> Void
}

extension OnboardingClient: TestDependencyKey {
    public static let testValue = OnboardingClient()

    public static let previewValue = OnboardingClient(
        enableTouchID: { },
        enableICloudSync: { .available },
        continueWithoutICloud: { },
        openICloudSystemSettings: { }
    )
}

extension DependencyValues {
    public var onboardingClient: OnboardingClient {
        get { self[OnboardingClient.self] }
        set { self[OnboardingClient.self] = newValue }
    }
}
