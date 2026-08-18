// Copyright © 2026 Devault. All rights reserved

import AppKit
import Foundation

import ComposableArchitecture
import DVCore
import DVData
import DVDomain
import DVPresentation

extension ICloudSettingsClient: @retroactive DependencyKey {
  public static let liveValue: ICloudSettingsClient = {
    let useCase: any ICloudSettingsUseCase = ICloudSettingsUseCaseImpl(
      repository: LiveRepositories.settings,
      iCloudService: ICloudServiceImpl(
        containerIdentifier: ICloudContainer.identifier,
        storageConfigurator: { enabled in
          try await LiveRepositories.storage.configure(iCloudSyncEnabled: enabled)
        }
      )
    )

    return ICloudSettingsClient(
      isEnabled: {
        useCase.isEnabled()
      },
      setEnabled: { enabled in
        try await useCase.setEnabled(enabled)
      },
      openSystemSettings: {
        // OnboardingClient+Live.swift와 동일한 딥링크. AppleIDPrefPane이 현재의 legacy bundle identifier.
        guard let url = URL(
          string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?icloud"
        ) else { return }
        NSWorkspace.shared.open(url)
      },
      lastUpdateDetectedAt: {
        useCase.lastUpdateDetectedAt()
      },
      remoteChangeStream: {
        useCase.remoteChangeStream()
      },
      accountStatus: {
        await useCase.accountStatus()
      }
    )
  }()
}
