// Copyright © 2026 Devault. All rights reserved

import Foundation
import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - AddToProjectView

struct AddToProjectView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<AddToProjectFeature>
  @State private var isProjectMenuPresented = false

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
      .sheet(
        item: $store.scope(state: \.destination?.createProject, action: \.destination.createProject)
      ) { createProjectStore in
        CreateProjectView(store: createProjectStore)
      }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension AddToProjectView {

  private var content: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Select Project")
        .dvFont(.bodyLG)
        .foregroundStyle(Color.dv(.black))

      projectPickerButton
        .floatingPanel(isPresented: $isProjectMenuPresented) {
          projectMenu
        }

      HStack(spacing: 12) {
        Spacer()
        Button("Cancel") {
          store.send(.didTapCancel)
        }
        .keyboardShortcut(.cancelAction)

        Button("Done") {
          store.send(.didTapDone)
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
        .disabled(store.selectedProjectID == nil)
      }
    }
    .padding(20)
    .frame(width: 420)
  }

  private var projectPickerButton: some View {
    Button {
      isProjectMenuPresented.toggle()
    } label: {
      HStack {
        Text(selectedProjectName ?? "Select a project")
          .dvFont(.bodyLG)
          .foregroundStyle(selectedProjectName == nil ? Color.dv(.gray400) : Color.dv(.gray900))
        Spacer()
        Image(systemName: "chevron.down")
          .dvFont(.captionMDRegular)
          .foregroundStyle(Color.dv(.gray500))
      }
      .padding(.horizontal, 12)
      .frame(width: DVComponentSize.md.width, height: 36)
      .background(Color.dv(.gray200))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var projectMenu: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(projects) { project in
        projectMenuRow(title: project.name) {
          store.send(.didSelectProject(id: project.id))
          isProjectMenuPresented = false
        }
      }

      if !projects.isEmpty {
        Divider()
          .padding(.vertical, 2)
      }

      projectMenuRow(title: "New Project...") {
        isProjectMenuPresented = false
        store.send(.didTapCreateNewProject)
      }
    }
    .padding(6)
    .frame(width: DVComponentSize.md.width)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .shadow(color: Color(nsColor: .shadowColor).opacity(0.15), radius: 16, y: 6)
  }

  private func projectMenuRow(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .dvFont(.bodyLG)
        .fontWeight(.regular)
        .foregroundStyle(Color.dv(.gray900))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
  }

  private var selectedProjectName: String? {
    guard let id = store.selectedProjectID else { return nil }
    return projects[id: id]?.name
  }

  private var projects: IdentifiedArrayOf<ProjectItem> {
    if case let .loaded(projects) = store.projectsState {
      return projects
    }
    return []
  }
}

// MARK: - Preview

#if DEBUG

#Preview {
  AddToProjectView(
    store: Store(initialState: AddToProjectFeature.State(secretID: UUID())) {
      AddToProjectFeature()
    } withDependencies: {
      $0.secretClient = .previewValue
    }
  )
}

#endif
