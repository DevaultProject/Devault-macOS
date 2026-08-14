// Copyright © 2026 Devault. All rights reserved

import AppKit

import ComposableArchitecture
import DVCore
import DVPresentation
import DVDomain
import DVData

extension OnboardingClient: @retroactive DependencyKey {
  public static let liveValue: OnboardingClient = {
    let accountService: any ICloudAccountService = CloudKitAccountServiceImpl(
      containerIdentifier: ICloudContainer.identifier
    )
    let iCloudSyncSettings: any ICloudSyncSettingsUseCase = ICloudSyncSettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )

    return OnboardingClient(
      enableTouchID: {
        try await LiveUseCases.authenticate.authenticate(reason: "Touch ID를 사용하려면 인증이 필요합니다")
      },
      enableICloudSync: {
        let status = await accountService.fetchAccountStatus()
        if status == .available {
          iCloudSyncSettings.setEnabled(true)
        }
        return status
      },
      openICloudSystemSettings: {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?icloud") else { return }
        NSWorkspace.shared.open(url)
      }
    )
  }()
}
