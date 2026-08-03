// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVCore
import DVPresentation
import DVDomain
import DVData

extension OnboardingClient: @retroactive DependencyKey {
  public static let liveValue: OnboardingClient = {
    let authenticationService: any UserAuthenticationService = LocalUserAuthenticationServiceImpl()
    let accountService: any ICloudAccountService = CloudKitAccountServiceImpl(
      containerIdentifier: ICloudContainer.identifier
    )
    let repository: any SettingsRepository = SettingsRepositoryImpl()
    let iCloudSyncSettings: any ICloudSyncSettingsUseCase = ICloudSyncSettingsUseCaseImpl(repository: repository)

    return OnboardingClient(
      enableTouchID: {
        try await authenticationService.authenticate(reason: "Touch ID를 사용하려면 인증이 필요합니다")
      },
      enableICloudSync: {
        let status = await accountService.fetchAccountStatus()
        if status == .available {
          iCloudSyncSettings.setEnabled(true)
        }
        return status
      }
    )
  }()
}
