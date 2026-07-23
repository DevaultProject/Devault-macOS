// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SidebarView

struct SidebarView: View {

  // MARK: - Properties

  @Bindable var store: StoreOf<SidebarFeature>

  // MARK: - Body

  var body: some View {
    content
      .task { store.send(.task) }
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

  // 임시 로고뷰 입니다.
  private var logoView: some View {
    HStack {
      Rectangle()
        .fill(Color.red)
        .frame(width: 52, height: 28)
        .overlay(
          Text("LOGO")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.black)
        )
      Spacer()
    }
  }

  private var filterGrid: some View {
    VStack(spacing: 12) {
      DVCategory(
        title: SidebarFilter.all.title,
        count: 0,
        systemImage: SidebarFilter.all.icon,
        isSelected: store.selection == .filter(.all)
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
            count: 0,
            systemImage: filter.icon,
            iconColor: filter.iconColor,
            isSelected: store.selection == .filter(filter)
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
        projectList
      } else {
        Spacer(minLength: 0)
      }
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

  // TODO: - contextMenu 확정 후 추후에 Action 추가
  private var projectList: some View {
    let projects = ["Project A", "Project B", "Project C"]
    // List(selection:)은 Int?를 요구하지만 store.selection은 SidebarSelection(enum)이라 타입 불일치로 $store 직접 바인딩 불가 → 의도적 manual Binding 사용
    return List(
      selection: Binding(
        get: {
          if case .project(let index) = store.selection { return index }
          return nil
        },
        set: { index in
          if let index { store.send(.didSelect(.project(index))) }
          // TODO: nil(deselect) 처리 — content 컬럼 연결 시 결정
        }
      )
    ) {
      ForEach(projects.indices, id: \.self) { index in
        DVProjectContainer(name: projects[index], count: 0)
          .tag(index)
          .contextMenu {
            Button("Rename") {}
            Button("New Secret") {}
            Divider()
            Button("Delete Project", role: .destructive) {}
          }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .padding(.horizontal, -12)
  }

  private var bottomBar: some View {
    HStack {
      circleIconButton(icon: "gearshape") { store.send(.didTapSettingsButton) }
        .accessibilityLabel("Settings")
      Spacer()
      circleIconButton(icon: "plus") { store.send(.didTapAddButton) }
        .accessibilityLabel("Add Secret")
    }
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
