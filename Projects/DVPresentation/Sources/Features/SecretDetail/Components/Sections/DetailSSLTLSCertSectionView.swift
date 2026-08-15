// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `sshAndCredentials`의 `.sslTlsCertificate` 서브타입 조회 섹션 —
/// 생성 화면 `SSLTLSCertSectionView`의 read-only 대응.
///
/// 생성 화면에 Services / Expire Date 입력이 없으므로 조회 화면도 그 두 행을 두지 않는다.
struct DetailSSLTLSCertSectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: SSLCertPayload
    /// 생성 폼의 "Renew Command" 입력이 `SSLCertMetadata.renewCommand`로 저장된다.
    let metadata: SSLCertMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Certificate"),
                value: payload.certificate,
                isSensitive: true,
                isCopyable: true,
                field: .certificate
            )

            DetailReadOnlyFieldView(
                label: .module("Private Key"),
                value: payload.privateKey,
                isSensitive: true,
                isCopyable: true,
                field: .sslPrivateKey
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

            DetailReadOnlyFieldView(
                label: .module("Certificate Chain"),
                value: payload.certificateChain ?? "",
                isSensitive: true,
                isCopyable: true,
                field: .certificateChain
            )

            DetailReadOnlyFieldView(
                label: .module("Renew Command"),
                value: metadata?.renewCommand ?? "",
                isCopyable: true
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

/// `matrix[7]`은 `environment`·`service`·`memo`가 nil이고 만료일만 과거로 채워져 있다 —
/// 공통 행이 거의 비어도 타입 필드 쪽 배열이 흐트러지지 않는지 확인.
#Preview("sslTlsCertificate · matrix[7] (420)") {
    ScrollView {
        DetailSSLTLSCertSectionView(
            secret: [Secret].previewSubTypeMatrix[7],
            linkedProjects: [Project].preview,
            // 인증서·개인키 형태의 문자열은 쓰지 않는다 — 가짜여도 시크릿 스캐너가 매번 탐지 결과를 올린다.
            payload: SSLCertPayload(
                certificate: "PREVIEW PLACEHOLDER — 실제 인증서가 아니다\n두 번째 줄",
                privateKey: "PREVIEW PLACEHOLDER — 실제 키가 아니다\n두 번째 줄",
                certificateChain: "PREVIEW PLACEHOLDER — 실제 체인이 아니다"
            ),
            metadata: SSLCertMetadata(renewCommand: "certbot renew --cert-name devault.app")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("sslTlsCertificate · 값 비어있음 · matrix[7]") {
    ScrollView {
        DetailSSLTLSCertSectionView(
            secret: [Secret].previewSubTypeMatrix[7],
            linkedProjects: [],
            payload: SSLCertPayload(certificate: "", privateKey: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
