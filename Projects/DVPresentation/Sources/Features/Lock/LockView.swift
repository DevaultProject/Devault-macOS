// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - LockView

public struct LockView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<LockFeature>

  // MARK: - Init

  public init(store: StoreOf<LockFeature>) {
    self.store = store
  }

  // MARK: - Body

  public var body: some View {
    content
      .dvScreenBackground()
      .alert($store.scope(state: \.alert, action: \.alert))
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
      DVButton(titleText: .module("Unlock with Touch ID"), style: .primary) {
        store.send(.didTapUnlock)
      }
      // Enter(Return)로도 바로 인증
      .keyboardShortcut(.defaultAction)
    }
  }

  private var appIconWithLogoView: some View {
    VStack(spacing: 20) {
      Image.dv(.appIcon)
        .resizable()
        .scaledToFit()
        .frame(width: 80)
      (
        Text("De").foregroundStyle(Color.dv(.vaultDark))
        + Text("Vault").foregroundStyle(Color.dv(.vaultGreen))
      )
      .font(.dv(.displayBrand))
    }
  }
}

// MARK: - Preview

#if DEBUG

#Preview {
  LockView(
    store: Store(initialState: LockFeature.State()) {
      LockFeature()
    }
  )
  .frame(width: 540, height: 400)
}

#endif
