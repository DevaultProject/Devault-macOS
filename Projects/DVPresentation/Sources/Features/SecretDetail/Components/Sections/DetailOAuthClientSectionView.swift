// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `oauth`의 `.oauthClient` 서브타입 조회 섹션 — 생성 화면 `OAuthClientSectionView`의 read-only 대응.
struct DetailOAuthClientSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: OAuthClientPayload
    /// 생성 폼의 "Redirect URL" / "Scope" 입력이 `OAuthClientMetadata`로 저장된다.
    let metadata: OAuthClientMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Client ID"),
                value: payload.clientId,
                isCopyable: true
            )

            DetailReadOnlyFieldView(
                label: .module("Client Secret"),
                value: payload.clientSecret,
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

            AdaptiveFieldRow {
                DetailReadOnlyFieldView(
                    label: .module("Expire Date"),
                    value: secret.expireDateDisplayText,
                    sizeMode: .paired
                )
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Environment"),
                    value: secret.environmentDisplayText,
                    sizeMode: .paired
                )
            }

            DetailReadOnlyFieldView(
                label: .module("Redirect URL"),
                value: metadata?.redirectUri ?? "",
                isCopyable: true
            )

            DetailReadOnlyFieldView(
                label: .module("Scope"),
                value: metadata?.scopes ?? ""
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

/// `matrix[3]`은 `environment`가 nil이라 Environment 슬롯만 Empty로 남는다 —
/// 페어 행 한쪽만 비어도 행 높이가 어긋나지 않는지 확인.
#Preview("oauthClient · matrix[3] (420)") {
    ScrollView {
        DetailOAuthClientSectionView(
            secret: [Secret].previewSubTypeMatrix[3],
            linkedProjects: [Project].preview,
            payload: OAuthClientPayload(
                clientId: "1234567890-abcdefg.apps.googleusercontent.com",
                clientSecret: "GOCSPX-1a2b3c4d5e6f7g8h9i0j"
            ),
            metadata: OAuthClientMetadata(
                redirectUri: "https://app.example/oauth/callback",
                scopes: "openid, profile, email"
            )
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("oauthClient · 값 비어있음 · matrix[3]") {
    ScrollView {
        DetailOAuthClientSectionView(
            secret: [Secret].previewSubTypeMatrix[3],
            linkedProjects: [],
            payload: OAuthClientPayload(clientId: "", clientSecret: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
