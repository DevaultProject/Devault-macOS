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
                isCopyable: true
            )

            DetailReadOnlyFieldView(
                label: .module("Private Key"),
                value: payload.privateKey,
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

            DetailReadOnlyFieldView(
                label: .module("Certificate Chain"),
                value: payload.certificateChain ?? "",
                isCopyable: true
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
            payload: SSLCertPayload(
                certificate: "-----BEGIN CERTIFICATE-----\nMIIDdzCCAl+gAwIBAgIE\n-----END CERTIFICATE-----",
                privateKey: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG\n-----END PRIVATE KEY-----",
                certificateChain: "-----BEGIN CERTIFICATE-----\nintermediate\n-----END CERTIFICATE-----"
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
