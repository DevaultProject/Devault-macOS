// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVCore
import DVData
import DVDomain
import DVPresentation

extension AppLaunchClient: @retroactive DependencyKey {
  public static let liveValue: AppLaunchClient = {
    let settingsRepository: any SettingsRepository = SettingsRepositoryImpl()
    let onboardingStatusUseCase: any OnboardingStatusUseCase = OnboardingStatusUseCaseImpl(
      repository: settingsRepository
    )

    let notificationService: any SecurityNotificationService = SecurityNotificationServiceImpl()
    let expiryUseCase: any ScheduleSecretExpiryNotificationsUseCase = ScheduleSecretExpiryNotificationsUseCaseImpl(
      repository: LiveRepositories.secret,
      notificationService: notificationService
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
          return try await notificationService.requestAuthorization()
        } catch {
          Log.warn("알림 권한 요청 실패: \(error)", category: .notification)
          return false
        }
      },
      syncExpiryNotifications: {
        do {
          try await expiryUseCase.syncAll()
        } catch {
          Log.warn("만료 알림 동기화 실패: \(error)", category: .notification)
        }
      }
    )
  }()
}
