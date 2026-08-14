// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVCore
import DVData
import DVDomain
import DVPresentation

extension AppLaunchClient: @retroactive DependencyKey {
  public static let liveValue: AppLaunchClient = {
    let onboardingStatusUseCase: any OnboardingStatusUseCase = OnboardingStatusUseCaseImpl(
      repository: LiveRepositories.settings
    )

    return AppLaunchClient(
      hasCompletedOnboarding: {
        onboardingStatusUseCase.hasCompleted()
      },
      setOnboardingCompleted: {
        onboardingStatusUseCase.setCompleted()
      },
      requestNotificationAuthorization: {
        do {
          return try await LiveServices.securityNotification.requestAuthorization()
        } catch {
          Log.warn("알림 권한 요청 실패: \(error)", category: .notification)
          return false
        }
      },
      syncExpiryNotifications: {
        do {
          try await LiveUseCases.expirySchedule.syncAll()
        } catch {
          Log.warn("만료 알림 동기화 실패: \(error)", category: .notification)
        }
      }
    )
  }()
}
