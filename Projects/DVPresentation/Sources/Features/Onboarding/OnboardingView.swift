// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import Lottie

// MARK: - OnboardingView

public struct OnboardingView: View {

  // MARK: - Properties

  @Bindable public var store: StoreOf<OnboardingFeature>

  // MARK: - Init

  public init(store: StoreOf<OnboardingFeature>) {
    self.store = store
  }

  // MARK: - Body

  public var body: some View {
    content
      .dvScreenBackground()
  }
}

// MARK: - Subviews

extension OnboardingView {

  private var content: some View {
    ZStack {
      stepContent
      VStack {
        Spacer()
        DVStepIndicator(totalSteps: 4, currentStep: store.currentStepIndex)
          .padding(.bottom, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var stepContent: some View {
    switch store.step {
    case .welcome:    welcomeView
    case .security:   securityView
    case .icloudSync: icloudSyncView
    case .syncing:    syncingView
    }
  }

  // MARK: 1.0 Welcome

  private var welcomeView: some View {
    VStack(spacing: 40) {
      appIconWithLogoView
      DVButton(titleText: "Start", style: .primary) {
        store.send(.didTapStart)
      }
    }
  }

  // MARK: 1.1 Security

  private var securityView: some View {
    VStack(spacing: 56) {
      appIconWithTextView("Your secrets are protected with Touch ID")
      VStack(spacing: 12) {
        DVButton(titleText: "Enable Touch ID", style: .primary) {
          store.send(.didTapEnableTouchID)
        }
        Text("If Touch ID is unavailable,\nsystem password will be used")
          .dvFont(.captionMDRegular)
          .foregroundStyle(Color.dv(.gray900))
          .multilineTextAlignment(.center)
      }
    }
  }

  // MARK: 1.2 iCloud Sync

  private var icloudSyncView: some View {
    VStack(spacing: 20) {
      appIconWithTextView("Sync your secrets with iCloud?")
      Text("Access your secrets on all your\nApple devices, securely encrypted.")
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.gray900))
        .multilineTextAlignment(.center)
        .padding(.bottom, 12)
      HStack(spacing: 16) {
        DVButton(titleText: "Not Now", style: .primarySmall) {
          store.send(.didTapNotNow)
        }
        DVButton(titleText: "Enable Sync", style: .primarySmall) {
          store.send(.didTapEnableSync)
        }
      }
    }
  }

  // MARK: 1.3 Syncing

  private var syncingView: some View {
    VStack(spacing: 24) {
      appIconWithTextView("Syncing...")
      LottieView {
        try await DotLottieFile.named("progress", bundle: DVDesignResources.bundle)
      }
      .playing(loopMode: .loop)
      .frame(width: 124, height: 62)
      Text("This may take a moment...")
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.gray900))
    }
  }

  // MARK: Shared

  private var appIcon: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(Color.dv(.gray800))
      .frame(width: 80, height: 80)
  }

  private var appIconWithLogoView: some View {
    VStack(spacing: 20) {
      appIcon
      (
        Text("De").foregroundStyle(Color.dv(.vaultDark))
        +
        Text("Vault").foregroundStyle(Color.dv(.vaultGreen))
      )
      .font(.dv(.displayBrand))
    }
  }

  private func appIconWithTextView(_ title: String) -> some View {
    VStack(spacing: 20) {
      appIcon
      Text(title)
        .dvFont(.headingXL)
        .foregroundStyle(Color.dv(.gray900))
    }
  }
}

// MARK: - Preview

#Preview("Welcome") {
  OnboardingView(
    store: Store(initialState: OnboardingFeature.State()) {
      OnboardingFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#Preview("Security") {
  OnboardingView(
    store: Store(
      initialState: OnboardingFeature.State(step: .security)
    ) {
      OnboardingFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#Preview("iCloud Sync") {
  OnboardingView(
    store: Store(
      initialState: OnboardingFeature.State(step: .icloudSync)
    ) {
      OnboardingFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#Preview("Syncing") {
  OnboardingView(
    store: Store(
      initialState: OnboardingFeature.State(step: .syncing)
    ) {
      OnboardingFeature()
    }
  )
  .frame(width: 540, height: 400)
}
