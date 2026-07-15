// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

// MARK: - AddToProjectView

struct AddToProjectView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<AddToProjectFeature>

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
  }
}

// MARK: - Subviews

extension AddToProjectView {

  private var content: some View {
    NavigationStack {
      list
        .navigationTitle("Add to Project")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { store.send(.didTapCancel) }
          }
        }
    }
    .frame(minWidth: 320, minHeight: 360)
  }

  private var list: some View {
    List(store.projects) { project in
      Button {
        store.send(.didTapProject(id: project.id))
      } label: {
        Text(project.name)
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
      }
      .buttonStyle(.plain)
    }
  }
}

// MARK: - Preview

#Preview {
  AddToProjectView(
    store: Store(initialState: AddToProjectFeature.State(secretID: UUID())) {
      AddToProjectFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
}
