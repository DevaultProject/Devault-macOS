// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

// MARK: - OnboardingStatusClient

@DependencyClient
public struct OnboardingStatusClient {
  public var hasCompleted: @Sendable () -> Bool = { false }
  public var setCompleted: @Sendable () -> Void
}

// MARK: - DependencyKey

extension OnboardingStatusClient: TestDependencyKey {
  public static let testValue = OnboardingStatusClient()

  public static let previewValue = OnboardingStatusClient(
    hasCompleted: { false },
    setCompleted: { }
  )
}

// MARK: - DependencyValues

extension DependencyValues {
  public var onboardingStatus: OnboardingStatusClient {
    get { self[OnboardingStatusClient.self] }
    set { self[OnboardingStatusClient.self] = newValue }
  }
}
