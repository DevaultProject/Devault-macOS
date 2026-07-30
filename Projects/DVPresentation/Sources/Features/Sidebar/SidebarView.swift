// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SidebarView

struct SidebarView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SidebarFeature>
  @Environment(\.openWindow) private var openWindow

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension SidebarView {

  private var content: some View {
    VStack(spacing: 10) {
      logoView
        .padding(.leading, 4)
      filterGrid
        .padding(.bottom, 10)
      projectSection
        .frame(maxHeight: .infinity)
      bottomBar
        .padding(.bottom, 10)
    }
    .padding(.horizontal, 12)
  }

  private var logoView: some View {
    HStack(spacing: 4) {
      Image.dv(.appIcon)
        .resizable()
        .scaledToFit()
        .frame(width: 28)
        
      (
        Text("De").foregroundStyle(Color.dv(.vaultDark))
        +
        Text("Vault").foregroundStyle(Color.dv(.vaultGreen))
      )
      .font(.dv(.headingXL))
      Spacer()
    }
  }

  private var filterGrid: some View {
    VStack(spacing: 12) {
      DVCategory(
        title: SidebarFilter.all.title,
        count: count(for: .all),
        systemImage: SidebarFilter.all.icon,
        isSelected: !store.isCreatingSecret && store.selection == .filter(.all)
      ) {
        store.send(.didSelect(.filter(.all)))
      }
      .frame(height: 72)

      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: 12
      ) {
        ForEach([SidebarFilter.starred, .notice, .expired, .deleted], id: \.self) { filter in
          DVCategory(
            title: filter.title,
            count: count(for: filter),
            systemImage: filter.icon,
            iconColor: filter.iconColor,
            isSelected: !store.isCreatingSecret && store.selection == .filter(filter)
          ) {
            store.send(.didSelect(.filter(filter)))
          }
          .frame(height: 72)
        }
      }
    }
  }

  private var projectSection: some View {
    VStack(spacing: 12) {
      projectSectionHeader
        .padding(.horizontal, 8)
      if store.isProjectSectionExpanded {
        projectSectionBody
      } else {
        Spacer(minLength: 0)
      }
    }
  }

  @ViewBuilder
  private var projectSectionBody: some View {
    switch store.projectsState {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
      Spacer(minLength: 0)
    case .loaded:
      projectList
    case .failed:
      Text("Failed to load")
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.danger))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
      Spacer(minLength: 0)
    }
  }

  private var projectSectionHeader: some View {
    HStack(spacing: 11) {
      Text("Project")
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
      Spacer()
      projectHeaderButton(icon: "plus.circle") { store.send(.didTapAddProject) }
        .accessibilityLabel("Add Project")
      projectHeaderButton(
        icon: store.isProjectSectionExpanded ? "chevron.down" : "chevron.up"
      ) {
        store.send(.didToggleProjectSection)
      }
      .accessibilityLabel(store.isProjectSectionExpanded ? "Collapse Projects" : "Expand Projects")
    }
  }

  private var projectList: some View {
    // List(selection:)은 ProjectItem.ID?를 요구하지만 store.selection은 SidebarSelection(enum)이라 타입 불일치로 $store 직접 바인딩 불가 → 의도적 manual Binding 사용
    List(
      selection: Binding<ProjectItem.ID?>(
        get: {
          guard !store.isCreatingSecret else { return nil }
          if case .project(id: let id) = store.selection { return id }
          return nil
        },
        set: { id in
          if let id { store.send(.didSelect(.project(id: id))) }
        }
      )
    ) {
      ForEach(store.projects) { project in
        projectRow(project)
          .tag(project.id)
          .contextMenu {
            Button("Rename") { store.send(.didTapRename(id: project.id)) }
            Button("New Secret") { store.send(.didTapAddButton) }
            Divider()
            Button("Delete Project", role: .destructive) {
              store.send(.didTapDelete(id: project.id))
            }
          }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .padding(.horizontal, -12)
    .onKeyPress(.return) {
      guard store.renamingProjectID == nil else { return .ignored }
      if case .project(id: let id) = store.selection {
        store.send(.didTapRename(id: id))
        return .handled
      }
      return .ignored
    }
  }

  @ViewBuilder
  private func projectRow(_ project: ProjectItem) -> some View {
    if store.renamingProjectID == project.id {
      DVProjectRenameContainer(
        text: Binding(
          get: { store.renameText },
          set: { store.send(.didChangeRenameText($0)) }
        ),
        onSubmit: { store.send(.didConfirmRename) },
        onCancel: { store.send(.didCancelRename) }
      )
    } else {
      DVProjectContainer(name: project.name, count: store.counts?.count(forProject: project.id))
    }
  }

  private var bottomBar: some View {
    HStack {
      circleIconButton(icon: "gearshape") {
        openWindow(id: "settings")
      }
      .accessibilityLabel("Settings")
      Spacer()
      circleIconButton(icon: "plus") { store.send(.didTapAddButton) }
        .accessibilityLabel("Add Secret")
    }
  }

  /// 개수는 로드 완료 후에만 실제 값을 갖는다. 로드 전·실패 시에는 nil을 넘겨
  /// 숫자 자리를 비운다 — 0으로 대체하면 "시크릿 없음"과 구분되지 않는다.
  private func count(for filter: SidebarFilter) -> Int? {
    store.counts?.count(for: filter)
  }

  private func projectHeaderButton(icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .dvFont(.captionLG)
        .foregroundStyle(Color.dv(.gray500))
    }
    .buttonStyle(.plain)
  }

  private func circleIconButton(icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .dvFont(.captionLG)
        .frame(width: 32, height: 32)
        .background(Color.dv(.vaultGreen), in: Circle())
        .foregroundStyle(Color.dv(.white))
    }
    .buttonStyle(.plain)
  }
}

// MARK: - SidebarFilter + View

private extension SidebarFilter {
  var iconColor: Color {
    switch self {
    case .notice:  Color.dv(.warning)
    case .expired: Color.dv(.danger)
    default:       Color.dv(.gray800)
    }
  }
}

// MARK: - Preview

#Preview {
  Group {
    SidebarView(
      store: Store(initialState: SidebarFeature.State()) {
        SidebarFeature()
      }
    )
    .frame(width: 200)

    SidebarView(
      store: Store(initialState: SidebarFeature.State()) {
        SidebarFeature()
      }
    )
    .frame(width: 250)

    SidebarView(
      store: Store(initialState: SidebarFeature.State()) {
        SidebarFeature()
      }
    )
    .frame(width: 270)
  }
}
