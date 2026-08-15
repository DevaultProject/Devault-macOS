// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `apiKeyToken`의 3 서브타입(apiKey / accessToken / webhookSecret) 공용 조회 섹션 —
/// 생성 화면 `APIKeysTokenSectionView`의 read-only 대응.
///
/// 3 서브타입이 한 뷰를 공유하는 것은 생성 화면과 같은 이유다 — payload 스키마가 동일하다.
struct DetailAPIKeysTokenSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: APIKeyPayload
    /// 생성 폼의 "Authority / Scope" 입력이 `APIKeyMetadata.scope`로 저장된다.
    let metadata: APIKeyMetadata?

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

            DetailReadOnlyFieldView(
                label: .module("Authority / Scope"),
                value: metadata?.scope ?? ""
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("apiKey · matrix[0] (420)") {
    ScrollView {
        DetailAPIKeysTokenSectionView(
            secret: [Secret].previewSubTypeMatrix[0],
            linkedProjects: [Project].preview,
            payload: APIKeyPayload(value: "ghp_1234567890abcdef"),
            metadata: APIKeyMetadata(scope: "repo:read, user:email")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

/// `matrix[1]`(accessToken)은 메타 필드가 전부 nil이다. payload·metadata까지 비워
/// `DVTextContainer`의 Empty 상태가 섹션 전체에 어떻게 깔리는지 확인한다.
#Preview("accessToken · 값 비어있음 · matrix[1]") {
    ScrollView {
        DetailAPIKeysTokenSectionView(
            secret: [Secret].previewSubTypeMatrix[1],
            linkedProjects: [],
            payload: APIKeyPayload(value: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
