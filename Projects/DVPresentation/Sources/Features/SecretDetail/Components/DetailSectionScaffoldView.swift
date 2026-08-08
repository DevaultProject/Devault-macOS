// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// 조회 화면 공통 메타 필드 스캐폴드 — 생성 화면 `FormSectionScaffold`의 read-only 대응.
///
/// 필드 순서는 CreateSecret SectionView와 **동일하게** 맞춘다 (결정 B-2).
/// `APIKeysTokenSectionView` 기준:
///
/// ```
/// Name                              ← fullWidth
/// primary()                         ← payload 주요 필드 (Value 등)
/// Project        | Services         ← paired
/// Expire Date    | Environment      ← paired
/// trailing()                        ← payload 보조 필드 (Authority / Scope 등)
/// Memo                              ← fullWidth
/// ```
///
/// 공통 메타 필드는 **payload 복호화 없이도 표시된다** — `Secret` 엔티티에서 바로 나오기 때문에
/// `payloadState`가 `.loading` / `.failed`여도 이 스캐폴드는 그대로 그려진다.
/// payload에 의존하는 필드만 `primary` / `trailing` 슬롯에 들어간다.
struct DetailSectionScaffoldView<Primary: View, Trailing: View>: View {

    let secret: Secret
    let linkedProjects: [Project]

    private let primary: () -> Primary
    private let trailing: () -> Trailing

    @Environment(\.formLayout) private var layout

    init(
        secret: Secret,
        linkedProjects: [Project],
        @ViewBuilder primary: @escaping () -> Primary,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.secret = secret
        self.linkedProjects = linkedProjects
        self.primary = primary
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: layout.rowSpacing) {
            DetailReadOnlyFieldView(
                label: .module("Name"),
                value: secret.name
            )

            primary()

            AdaptiveFieldRow {
                // 다중 값이므로 텍스트 한 줄이 아니라 chip 컨테이너로 표시한다 —
                // 생성 화면의 `DVMultiSelectDropdown` chip 트리거와 같은 모습.
                DetailProjectFieldView(projects: linkedProjects, sizeMode: .paired)
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

            trailing()

            DetailReadOnlyFieldView(
                label: .module("Memo"),
                value: secret.memoDisplayText
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Convenience init

extension DetailSectionScaffoldView where Trailing == EmptyView {

    /// 공통 메타 필드 아래에 오는 payload 보조 필드가 없는 경우.
    init(
        secret: Secret,
        linkedProjects: [Project],
        @ViewBuilder primary: @escaping () -> Primary
    ) {
        self.init(secret: secret, linkedProjects: linkedProjects, primary: primary, trailing: { EmptyView() })
    }
}

extension DetailSectionScaffoldView where Primary == EmptyView, Trailing == EmptyView {

    /// payload 필드 없이 공통 메타 필드만 표시. payload 섹션 구현 전 임시 경로이기도 하다.
    init(secret: Secret, linkedProjects: [Project]) {
        self.init(
            secret: secret,
            linkedProjects: linkedProjects,
            primary: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

// MARK: - Preview

#if DEBUG

private let _previewProjects: [Project] = [
    Project(id: UUID(), name: "Backend", createdAt: Date(), updatedAt: Date()),
]

private func _previewSecret(
    service: String? = "GitHub",
    environment: String? = SecretEnvironment.prod.rawValue,
    expiresAt: Date? = Date(timeIntervalSince1970: 1_800_000_000),
    memo: String? = "Rotate quarterly"
) -> Secret {
    Secret(
        id: UUID(),
        name: "GitHub Personal Token",
        secretType: .apiKeyToken,
        subType: .accessToken,
        service: service,
        environment: environment,
        expiresAt: expiresAt,
        memo: memo,
        createdAt: Date(),
        updatedAt: Date(),
        payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
    )
}

#Preview("Detail 컬럼 최소폭 (420 · 페어 2열 xs)") {
    ScrollView {
        DetailSectionScaffoldView(secret: _previewSecret(), linkedProjects: _previewProjects) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: "ghp_1234567890abcdef",
                isSensitive: true,
                isCopyable: true
            )
        }
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("Detail 넓은 컬럼 (700 · 페어가 함께 늘어남)") {
    ScrollView {
        DetailSectionScaffoldView(secret: _previewSecret(), linkedProjects: _previewProjects) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: "ghp_1234567890abcdef",
                isSensitive: true,
                isCopyable: true
            )
        }
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(700)
}

#Preview("2열 폼 (dual)") {
    ScrollView {
        DetailSectionScaffoldView(secret: _previewSecret(), linkedProjects: _previewProjects) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: "ghp_1234567890abcdef",
                isSensitive: true,
                isCopyable: true
            )
        } trailing: {
            DetailReadOnlyFieldView(
                label: .module("Authority / Scope"),
                value: "repo:read, user:email"
            )
        }
        .padding(20)
    }
    .formLayout(.dual)
    .previewWidth(.wide)
}

/// optional 필드가 모두 비어 있으면 `DVTextContainer`의 Empty 상태(박스만)로 표시된다.
#Preview("optional 전부 비어있음") {
    ScrollView {
        DetailSectionScaffoldView(
            secret: _previewSecret(service: nil, environment: nil, expiresAt: nil, memo: nil),
            linkedProjects: []
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
