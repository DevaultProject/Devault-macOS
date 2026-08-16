// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import DVPresentation

extension WindowCaptureBlockerClient: @retroactive DependencyKey {
  public static let liveValue: WindowCaptureBlockerClient = {
    let useCase: any SecuritySettingsUseCase = SecuritySettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )

    return WindowCaptureBlockerClient(
      enabledStream: {
        useCase.hideDuringScreenRecordingEnabledStream()
      }
    )
  }()
}
