// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `environmentVariableSet` 조회 섹션 (subType 없음) —
/// 생성 화면 `EnvSetSectionView`의 read-only 대응.
///
/// metadata 스키마가 없는 타입이라 `metadata` 파라미터를 받지 않는다.
/// 생성 화면에 Services / Expire Date 입력이 없으므로 조회 화면도 그 두 행을 두지 않는다.
struct DetailEnvSetSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: EnvSetPayload

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("envSet List"),
                value: payload.content,
                isSensitive: true,
                isCopyable: true
            )

            AdaptiveFieldRow {
                DetailProjectFieldView(projects: linkedProjects)
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Environment"),
                    value: secret.environmentDisplayText,
                    sizeMode: .paired
                )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

/// 여러 줄 값이 단일 라인 컨테이너에 들어가는 케이스 — 생성 화면도 한 줄로 받으므로
/// 넘치는 부분은 `DVTextContainer`의 가로 스크롤이 처리한다.
#Preview("environmentVariableSet · matrix[8] (420)") {
    ScrollView {
        DetailEnvSetSectionView(
            secret: [Secret].previewSubTypeMatrix[8],
            linkedProjects: [Project].preview,
            payload: EnvSetPayload(content: "DATABASE_URL=postgres://...\nSECRET_KEY=abc123")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("environmentVariableSet · 값 비어있음 · matrix[8]") {
    ScrollView {
        DetailEnvSetSectionView(
            secret: [Secret].previewSubTypeMatrix[8],
            linkedProjects: [],
            payload: EnvSetPayload(content: "")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
