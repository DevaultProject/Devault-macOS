// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign
import DVDomain

/// 조회 화면의 Project 필드 — 생성 화면 `ProjectFieldView`의 read-only 대응.
///
/// 값이 개별 항목의 집합이라 텍스트(`DetailReadOnlyFieldView`)가 아니라
/// `DVChipsContainer`로 표시한다. 생성 화면이 `DVMultiSelectDropdown`의 chip 트리거로
/// 보여주는 것과 같은 모습이다.
///
/// 연결된 프로젝트가 없으면 chip 없이 박스만 남는다 — 다른 optional 필드의 Empty 상태와 동일.
struct DetailProjectFieldView: View {

    let projects: [Project]
    var sizeMode: FormSlotSize = .paired

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    var body: some View {
        DVLabeledField(.module("Project"), size: size) {
            DVChipsContainer(projects.map(\.name), size: size)
        }
    }
}

// MARK: - Preview

#if DEBUG

private func _projects(_ names: [String]) -> [Project] {
    names.map { Project(id: UUID(), name: $0, createdAt: Date(), updatedAt: Date()) }
}

#Preview("단일 · paired (detail 최소폭)") {
    DetailProjectFieldView(projects: _projects(["Backend"]))
        .padding()
        .formLayout(.detailFluid)
        .previewWidth(420)
}

#Preview("다중 · paired") {
    DetailProjectFieldView(projects: _projects(["Backend", "Infra", "Mobile"]))
        .padding()
        .formLayout(.detailFluid)
        .previewWidth(420)
}

#Preview("비어있음") {
    DetailProjectFieldView(projects: [])
        .padding()
        .formLayout(.detailFluid)
        .previewWidth(420)
}

#Preview("dual") {
    DetailProjectFieldView(projects: _projects(["Backend", "Longlonglong Project Name"]))
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#endif
