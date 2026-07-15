// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

// MARK: - SecretListView

struct SecretListView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SecretListFeature>

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
  }
}

// MARK: - Subviews

extension SecretListView {

  private var content: some View {
    List(selection: selectedSecretIDBinding) {
      ForEach(store.secrets) { secret in
        DVVaultContainer(
          name: secret.name,
          date: secret.updatedAt.formatted(date: .numeric, time: .omitted),
          isSelected: secret.id == store.selectedSecretID
        )
        .tag(secret.id)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .tint(Color.dv(.vaultGreen))
  }

  private var selectedSecretIDBinding: Binding<Secret.ID?> {
    Binding(
      get: { store.selectedSecretID },
      set: { store.send(.didSelectSecret(id: $0)) }
    )
  }
}

// MARK: - Preview

#Preview {
  SecretListView(
    store: Store(initialState: SecretListFeature.State()) {
      SecretListFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
  .frame(width: 300, height: 500)
}
