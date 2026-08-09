// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `oauth`의 `.serviceAccount` 서브타입 조회 섹션 —
/// 생성 화면 `ServiceAccountSectionView`의 read-only 대응.
///
/// 생성 화면이 Environment를 노출하지 않으므로 조회 화면도 노출하지 않는다 —
/// 입력 경로가 없는 값을 조회 화면만 보여주면 항상 비어 보인다.
struct DetailServiceAccountSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: ServiceAccountPayload
    /// 생성 폼의 "Authority / Scope" 입력이 `ServiceAccountMetadata.authority`로 저장된다.
    let metadata: ServiceAccountMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Certification JSON"),
                value: payload.credentialJSON,
                isSensitive: true,
                isCopyable: true
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

            AdaptiveFieldRow(left: {
                DetailReadOnlyFieldView(
                    label: .module("Expire Date"),
                    value: secret.expireDateDisplayText,
                    sizeMode: .paired
                )
            })

            DetailReadOnlyFieldView(
                label: .module("Authority / Scope"),
                value: metadata?.authority ?? ""
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

/// `matrix[4]`는 `service`·`expiresAt`이 nil — Expire Date 단독 행이 비었을 때
/// dual/fluid 어느 쪽에서도 오른쪽 절반이 유령 여백으로 남지 않는지 확인.
#Preview("serviceAccount · matrix[4] (420)") {
    ScrollView {
        DetailServiceAccountSectionView(
            secret: [Secret].previewSubTypeMatrix[4],
            linkedProjects: [Project].preview,
            payload: ServiceAccountPayload(
                credentialJSON: #"{"type": "service_account", "project_id": "devault-preview"}"#
            ),
            metadata: ServiceAccountMetadata(authority: "organization-admin")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("serviceAccount · 값 비어있음 · matrix[4]") {
    ScrollView {
        DetailServiceAccountSectionView(
            secret: [Secret].previewSubTypeMatrix[4],
            linkedProjects: [],
            payload: ServiceAccountPayload(credentialJSON: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
