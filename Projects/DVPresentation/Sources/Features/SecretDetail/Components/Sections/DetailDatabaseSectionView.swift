// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `database` 조회 섹션 (subType 없음) — 생성 화면 `DatabaseSectionView`의 read-only 대응.
struct DetailDatabaseSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: DatabasePayload
    /// 생성 폼의 "SSL Required" 체크가 `DatabaseMetadata.sslRequired`로 저장된다.
    let metadata: DatabaseMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Link String"),
                value: payload.linkString,
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
                DetailExpireDateFieldView(secret: secret)
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Environment"),
                    value: secret.environmentDisplayText,
                    sizeMode: .paired
                )
            }

            DetailSSLRequiredFieldView(isRequired: isSSLRequired)
        }
    }

    /// `sslRequired`는 도메인에서 Optional이고 metadata 자체가 없는 기존 데이터도 있다.
    /// 어느 쪽이 nil이든 미설정 = 요구하지 않음으로 읽는다.
    private var isSSLRequired: Bool {
        metadata?.sslRequired ?? false
    }
}

// MARK: - Preview

#if DEBUG

#Preview("database · matrix[5] (420)") {
    ScrollView {
        DetailDatabaseSectionView(
            secret: [Secret].previewSubTypeMatrix[5],
            linkedProjects: [Project].preview,
            payload: DatabasePayload(linkString: "postgresql://admin:pass@db.example.com:5432/main"),
            metadata: DatabaseMetadata(sslRequired: true)
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

/// metadata가 nil인 케이스 — SSL Required 체크박스가 해제 상태로 떨어지는지 확인.
#Preview("database · 값 비어있음 · matrix[5]") {
    ScrollView {
        DetailDatabaseSectionView(
            secret: [Secret].previewSubTypeMatrix[5],
            linkedProjects: [],
            payload: DatabasePayload(linkString: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
