// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `sshAndCredentials`의 `.sshKey` 서브타입 조회 섹션 —
/// 생성 화면 `SSHKeySectionView`의 read-only 대응.
///
/// 생성 화면에 Services / Expire Date 입력이 없으므로 조회 화면도 그 두 행을 두지 않는다.
struct DetailSSHKeySectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: SSHKeyPayload
    /// 생성 폼의 "Public Key" / "Host" / "Username" 입력이 `SSHKeyMetadata`로 저장된다.
    let metadata: SSHKeyMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("Private Key"),
                value: payload.privateKey,
                isSensitive: true,
                isCopyable: true,
                field: .privateKey
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
                label: .module("Public Key"),
                value: metadata?.publicKey ?? "",
                isCopyable: true
            )

            DetailReadOnlyFieldView(
                label: .module("PassPhrase"),
                value: payload.passphrase ?? "",
                isSensitive: true,
                isCopyable: true,
                field: .passphrase
            )

            AdaptiveFieldRow {
                DetailReadOnlyFieldView(
                    label: .module("Host"),
                    value: metadata?.host ?? "",
                    sizeMode: .paired
                )
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Username"),
                    value: metadata?.username ?? "",
                    sizeMode: .paired
                )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

/// `matrix[6]`의 memo가 "passphrase 없음"이라 payload도 `passphrase: nil`로 맞춘다 —
/// Optional payload 필드가 Empty 상태로 떨어지는 경로를 채운 케이스에서도 확인한다.
#Preview("sshKey · matrix[6] (420)") {
    ScrollView {
        DetailSSHKeySectionView(
            secret: [Secret].previewSubTypeMatrix[6],
            linkedProjects: [Project].preview,
            payload: SSHKeyPayload(
                privateKey: "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEA\n-----END OPENSSH PRIVATE KEY-----",
                passphrase: nil
            ),
            metadata: SSHKeyMetadata(
                publicKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB deploy@example",
                host: "bastion.example.com",
                username: "ubuntu"
            )
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("sshKey · 값 비어있음 · matrix[6]") {
    ScrollView {
        DetailSSHKeySectionView(
            secret: [Secret].previewSubTypeMatrix[6],
            linkedProjects: [],
            payload: SSHKeyPayload(privateKey: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
