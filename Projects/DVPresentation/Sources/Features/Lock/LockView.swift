// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - LockView

public struct LockView: View {

  // MARK: - Properties

  @Bindable public var store: StoreOf<LockFeature>

  // MARK: - Init

  public init(store: StoreOf<LockFeature>) {
    self.store = store
  }

  // MARK: - Body

  public var body: some View {
    content
      .dvScreenBackground()
  }
}

// MARK: - Subviews

extension LockView {

  private var content: some View {
    unlockView
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var unlockView: some View {
    VStack(spacing: 40) {
      appIconWithLogoView
      DVButton(titleText: "Unlock with Touch ID", style: .primary) {
        store.send(.didTapUnlock)
      }
    }
  }

  private var appIconWithLogoView: some View {
    VStack(spacing: 20) {
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.dv(.gray800))
        .frame(width: 80, height: 80)
      (
        Text("De").foregroundStyle(Color.dv(.vaultDark))
        + Text("Vault").foregroundStyle(Color.dv(.vaultGreen))
      )
      .font(.dv(.displayBrand))
    }
  }
}

// MARK: - Preview

#Preview("Post Onboarding") {
  LockView(
    store: Store(initialState: LockFeature.State(isPostOnboarding: true)) {
      LockFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#Preview("Re-entry / Locked") {
  LockView(
    store: Store(initialState: LockFeature.State(isPostOnboarding: false)) {
      LockFeature()
    }
  )
  .frame(width: 540, height: 400)
}
