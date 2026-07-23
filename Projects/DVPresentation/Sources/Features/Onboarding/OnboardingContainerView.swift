// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - OnboardingContainerView

public struct OnboardingContainerView: View {

  // MARK: - Properties

  @Bindable public var store: StoreOf<OnboardingContainerFeature>

  // MARK: - Init

  public init(store: StoreOf<OnboardingContainerFeature>) {
    self.store = store
  }

  // MARK: - Body

  public var body: some View {
    content
      .dvScreenBackground()
  }
}

// MARK: - Subviews

extension OnboardingContainerView {
    
  private var content: some View {
    ZStack {
      stepView
      VStack {
        Spacer()
        DVStepIndicator(totalSteps: 4, currentStep: store.currentStepIndex)
          .padding(.bottom, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var stepView: some View {
    if let store = store.scope(state: \.onboarding, action: \.onboarding) {
      OnboardingView(store: store)
    } else if let store = store.scope(state: \.lock, action: \.lock) {
      LockView(store: store)
    }
  }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
  OnboardingContainerView(
    store: Store(initialState: OnboardingContainerFeature.State()) {
      OnboardingContainerFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#Preview("Lock Step") {
  OnboardingContainerView(
    store: Store(
      initialState: OnboardingContainerFeature.State(showingLock: true)
    ) {
      OnboardingContainerFeature()
    }
  )
  .frame(width: 540, height: 400)
}
