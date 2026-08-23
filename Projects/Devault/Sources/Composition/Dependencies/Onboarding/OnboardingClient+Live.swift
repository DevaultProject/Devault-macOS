// Copyright © 2026 Devault. All rights reserved

import AppKit

import ComposableArchitecture
import DVCore
import DVData
import DVDomain
import DVPresentation

extension OnboardingClient: @retroactive DependencyKey {
  public static let liveValue: OnboardingClient = {
    let iCloudSettingsUseCase: any ICloudSettingsUseCase = ICloudSettingsUseCaseImpl(
      repository: LiveRepositories.settings,
      iCloudService: ICloudServiceImpl(
        containerIdentifier: ICloudContainer.identifier,
        storageConfigurator: { enabled in
          try await LiveRepositories.storage.configure(iCloudSyncEnabled: enabled)
        }
      ),
      entitlementUseCase: LiveUseCases.entitlement
    )

    return OnboardingClient(
      enableTouchID: {
        try await LiveUseCases.authenticate.authenticate(reason: .enableTouchID)
      },
      enableICloudSync: {
        let status = await iCloudSettingsUseCase.accountStatus()
        if status == .available {
          try await iCloudSettingsUseCase.setEnabled(true)
        }
        return status
      },
      continueWithoutICloud: {
        do {
          try await iCloudSettingsUseCase.setEnabled(false)
        } catch {
          Log.error("로컬 저장소 구성 실패: \(error)", category: .storage)
        }
      },
      openICloudSystemSettings: {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?icloud") else { return }
        NSWorkspace.shared.open(url)
      }
    )
  }()
}
