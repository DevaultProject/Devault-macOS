// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `etc`의 `.custom` 서브타입 조회 섹션 — 생성 화면 `CustomSectionView`의 read-only 대응.
///
/// metadata 스키마가 없는 타입이라 `metadata` 파라미터를 받지 않는다.
struct DetailCustomSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: CustomPayload

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: payload.value,
                isSensitive: true,
                isCopyable: true,
                field: .value
            )

            AdaptiveFieldRow {
                DetailProjectFieldView(projects: linkedProjects)
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Services"),
                    value: secret.serviceDisplayText,
                    sizeMode: .paired
                )
            }

            AdaptiveFieldRow {
                DetailExpireDateFieldView(secret: secret)
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

/// `matrix[10]`은 여러 줄 memo를 가진 유일한 픽스처 — 스캐폴드 Memo 행이 줄바꿈을 어떻게
/// 처리하는지 이 섹션에서 확인한다.
#Preview("custom · matrix[10] (420)") {
    ScrollView {
        DetailCustomSectionView(
            secret: [Secret].previewSubTypeMatrix[10],
            linkedProjects: [Project].preview,
            payload: CustomPayload(value: "custom-secret-value")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("custom · 값 비어있음 · matrix[10]") {
    ScrollView {
        DetailCustomSectionView(
            secret: [Secret].previewSubTypeMatrix[10],
            linkedProjects: [],
            payload: CustomPayload(value: "")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
