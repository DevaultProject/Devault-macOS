// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import DVPresentation

extension SecuritySettingsClient: @retroactive DependencyKey {
  public static let liveValue: SecuritySettingsClient = {
    let useCase: any SecuritySettingsUseCase = SecuritySettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )

    return SecuritySettingsClient(
      isRequireAuthOnLaunchEnabled: {
        useCase.isRequireAuthOnLaunchEnabled()
      },
      setRequireAuthOnLaunchEnabled: { enabled in
        useCase.setRequireAuthOnLaunchEnabled(enabled)
      },
      isRequireAuthToCopyEnabled: {
        useCase.isRequireAuthToCopyEnabled()
      },
      setRequireAuthToCopyEnabled: { enabled in
        useCase.setRequireAuthToCopyEnabled(enabled)
      },
      isAutoLockEnabled: {
        useCase.isAutoLockEnabled()
      },
      setAutoLockEnabled: { enabled in
        useCase.setAutoLockEnabled(enabled)
      },
      autoLockMinutes: {
        useCase.autoLockMinutes()
      },
      setAutoLockMinutes: { minutes in
        useCase.setAutoLockMinutes(minutes)
      },
      isAutoClearClipboardEnabled: {
        useCase.isAutoClearClipboardEnabled()
      },
      setAutoClearClipboardEnabled: { enabled in
        useCase.setAutoClearClipboardEnabled(enabled)
      },
      autoClearClipboardDelaySeconds: {
        useCase.autoClearClipboardDelaySeconds()
      },
      setAutoClearClipboardDelaySeconds: { seconds in
        useCase.setAutoClearClipboardDelaySeconds(seconds)
      },
      isWindowCaptureProtectionEnabled: {
        useCase.isWindowCaptureProtectionEnabled()
      },
      setWindowCaptureProtectionEnabled: { enabled in
        useCase.setWindowCaptureProtectionEnabled(enabled)
      }
    )
  }()
}
