// Copyright © 2026 Devault. All rights reserved

import DVDesign
import DVDomain
import SwiftUI

/// CreateSecret 폼의 Project 필드 (모든 secretType 공통, optional).
/// `SecretMetaFields.projectIds`(Array)에 바인딩. `DVMultiSelectDropdown`이 Set 기반이라
/// 내부에서 Array↔Set 어댑터로 브리지.
///
/// 검색 헤더는 비활성(자산 규모가 작아 불필요). Add-new footer는 활성 —
/// `onCreateProject` 콜백이 발동되면 상위에서 생성 시트를 라우팅.
struct ProjectFieldView: View {

    @Binding var projectIds: [Project.ID]
    let availableProjects: [Project]
    let onCreateProject: () -> Void
    var sizeMode: LabeledTextFieldView.SizeMode = .fullWidth

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize {
        switch sizeMode {
        case .fullWidth: return mode.fullWidthFieldSize
        case .paired:    return mode.pairedFieldSize
        }
    }

    var body: some View {
        DVLabeledField("Project", size: size) {
            DVMultiSelectDropdown(
                "Select Project",
                items: availableProjects,
                selection: setBinding,
                label: \.name,
                size: size,
                onCreate: onCreateProject,
                createLabel: "Add new project",
                emptyMessage: "No projects yet",
                groupsSelectedAtTop: true
            )
        }
    }

    /// Array<Project.ID> ↔ Set<Project.ID> 어댑터.
    /// 도메인은 Array (순서 보존 여지), UI는 Set (multi-select 특성).
    /// 현재 정렬 규칙 없음 — set→array 변환 순서는 arbitrary.
    private var setBinding: Binding<Set<Project.ID>> {
        Binding(
            get: { Set(projectIds) },
            set: { projectIds = Array($0) }
        )
    }
}

// MARK: - Preview

#if DEBUG

private let previewProjects: [Project] = [
    Project(id: UUID(), name: "DeVault",     createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "DrinkiG",     createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "CheerLot",    createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "SipStream",   createdAt: Date(), updatedAt: Date()),
    Project(id: UUID(), name: "Example",     createdAt: Date(), updatedAt: Date()),
]

#Preview("Empty · Dual") {
    ProjectFieldPreview()
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("With selection · Single") {
    ProjectFieldPreview(initial: Array(previewProjects.prefix(2).map(\.id)))
        .padding()
        .environment(\.formLayoutMode, .single)
        .previewWidth(.narrow)
}

#Preview("No projects yet") {
    ProjectFieldPreview(items: [])
        .padding()
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

private struct ProjectFieldPreview: View {
    let items: [Project]
    @State private var projectIds: [Project.ID]

    init(initial: [Project.ID] = [], items: [Project] = previewProjects) {
        self._projectIds = State(initialValue: initial)
        self.items = items
    }

    var body: some View {
        ProjectFieldView(
            projectIds: $projectIds,
            availableProjects: items,
            onCreateProject: {}
        )
    }
}

#endif
