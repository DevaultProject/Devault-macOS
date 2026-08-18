// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - CreateProjectView

struct CreateProjectView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<CreateProjectFeature>

  // MARK: - Body

  var body: some View {
    content
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension CreateProjectView {

  private var content: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(.module("Create Project"))
            .dvFont(.bodyLG)
        .foregroundStyle(Color.dv(.black))

      VStack(alignment: .leading, spacing: 8) {
        Text(.module("Project Name"))
          .dvFont(.bodyMD)
          .foregroundStyle(Color.dv(.gray700))
        DVTextField(.module("e.g DeVault"), text: nameBinding, size: .md)
          .onSubmit { store.send(.didTapCreate) }
      }

      HStack(spacing: 10) {
        Spacer()
        DVButton(titleText: .module("Cancel"), style: .secondary) {
          store.send(.didTapCancel)
        }
        .keyboardShortcut(.cancelAction)

        DVButton(titleText: .module("Create"), style: .secondaryProminent) {
          store.send(.didTapCreate)
        }
        .keyboardShortcut(.defaultAction)
        .disabled(store.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .padding(20)
    .frame(width: 420)
  }

  private var nameBinding: Binding<String> {
    Binding(
      get: { store.name },
      set: { store.send(.didChangeName($0)) }
    )
  }
}

// MARK: - Preview

#if DEBUG

#Preview {
  CreateProjectView(
    store: Store(initialState: CreateProjectFeature.State()) {
      CreateProjectFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
}

#endif
