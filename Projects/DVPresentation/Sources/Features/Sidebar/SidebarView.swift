// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SidebarView

struct SidebarView: View {

  // MARK: - Metrics

  private enum Metrics {
    /// 갱신 중 이전 값에 씌우는 흐림. 더 낮추면 목록이 비활성처럼 보인다.
    static let refreshingOpacity: Double = 0.55
    static let fade: Animation = .easeInOut(duration: 0.18)
  }

  // MARK: - Properties

  @Bindable var store: StoreOf<SidebarFeature>

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
        isSelected: store.highlighted == .filter(.all)
      ) {
        store.send(.didSelect(.filter(.all)))
      }
      .frame(height: 72)
      .accessibilityElement(children: .combine)

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
            isSelected: store.highlighted == .filter(filter)
          ) {
            store.send(.didSelect(.filter(filter)))
          }
          .frame(height: 72)
          .accessibilityElement(children: .combine)
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
    // `value`를 좁히지 않으면 이름 변경 입력 한 글자마다 섹션 전체가 다시 애니메이션된다.
    .animation(Metrics.fade, value: store.projectsState)
    .animation(Metrics.fade, value: store.isRefreshingProjects)
  }

  /// 스피너 대신 자리를 유지한 채 opacity만 움직인다. 갱신이 잦은 화면이라(시크릿 생성, 프로젝트
  /// 추가·이름 변경·삭제) 스피너로 갈아끼우면 목록이 사라졌다 나타나는 것으로 보인다.
  @ViewBuilder
  private var projectSectionBody: some View {
    if case .failed = store.projectsState {
      Text(.module("Failed to load"))
        .dvFont(.bodyMD)
        .foregroundStyle(Color.dv(.danger))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
      Spacer(minLength: 0)
    } else if store.projects.isEmpty {
      // 아직 못 받았거나 정말로 비어 있다. 둘 다 보여줄 것이 없으므로 자리만 잡아 둔다.
      Spacer(minLength: 0)
    } else {
      projectList
        .opacity(store.isRefreshingProjects ? Metrics.refreshingOpacity : 1)
    }
  }

  private var projectSectionHeader: some View {
    HStack(spacing: 11) {
      Text(.module("Project"))
        .dvFont(.captionMDSemibold)
        .foregroundStyle(Color.dv(.vaultGreen))
      Spacer()
      projectHeaderButton(icon: "plus.circle") { store.send(.didTapAddProject) }
        .accessibilityLabel(String.module("Add Project"))
      projectHeaderButton(
        icon: store.isProjectSectionExpanded ? "chevron.down" : "chevron.up"
      ) {
        store.send(.didToggleProjectSection)
      }
      .accessibilityLabel(store.isProjectSectionExpanded ? String.module("Collapse Projects") : String.module("Expand Projects"))
    }
  }

  private var projectList: some View {
    // List(selection:)은 ProjectItem.ID?를 요구하지만 store.selection은 SidebarSelection(enum)이라 타입 불일치로 $store 직접 바인딩 불가 → 의도적 manual Binding 사용
    List(
      selection: Binding<ProjectItem.ID?>(
        get: {
          if case .project(id: let id) = store.highlighted { return id }
          return nil
        },
        set: { id in
          if let id { store.send(.didSelect(.project(id: id))) }
        }
      )
    ) {
      ForEach(store.projects) { project in
        projectRow(project)
          .accessibilityElement(children: .combine)
          .tag(project.id)
          .contextMenu {
            Button(String.module("Rename")) { store.send(.didTapRename(id: project.id)) }
            Button(String.module("New Secret")) { store.send(.didTapAddButton) }
            Divider()
            Button(String.module("Delete Project"), role: .destructive) {
              store.send(.didTapDelete(id: project.id))
            }
          }
      }
    }
    .listStyle(.sidebar)
    // 프로젝트가 추가·삭제·이름 변경될 때 행이 뚝 나타나지 않게 한다. `refresh` 경로가 목록을
    // 비우지 않으므로 실제로 바뀐 행만 움직인다.
    .animation(.smooth(duration: 0.25), value: store.projects)
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
        store.send(.didTapSettings)
      }
      .accessibilityLabel(String.module("Settings"))
      Spacer()
      circleIconButton(icon: "plus") { store.send(.didTapAddButton) }
        .accessibilityLabel(String.module("Add Secret"))
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

#if DEBUG

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

#endif
