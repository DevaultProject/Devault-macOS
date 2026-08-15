// Copyright © 2026 Devault. All rights reserved

import Foundation

// MARK: - 필드 식별자로 payload 값 꺼내기

/// 조회 화면이 복사할 값을 찾을 때 쓴다.
///
/// 뷰가 값을 들고 있다가 복사 액션에 실어 보내는 방법도 있지만, 그러면 **마스킹된 필드의 원문이
/// 뷰 트리를 통과**하게 된다. 뷰에는 식별자만 넘기고 값은 Feature가 payload에서 직접 꺼낸다.
///
/// 해당 payload에 없는 필드를 물으면 빈 문자열을 준다 — 화면에 없는 필드의 복사 버튼이 눌릴 일은
/// 없고, 있더라도 빈 문자열을 클립보드에 쓰는 것이 잘못된 값을 쓰는 것보다 안전하다.
extension CreateSecretPayload {

    func value(for field: SecretFieldID) -> String {
        switch self {
        case .apiKey(let payload, _), .accessToken(let payload, _), .webhookSecret(let payload, _):
            return field == .value ? payload.value : ""

        case .oauthClient(let payload, _):
            switch field {
            case .clientId:     return payload.clientId
            case .clientSecret: return payload.clientSecret
            default:            return ""
            }

        case .serviceAccount(let payload, _):
            return field == .credentialJSON ? payload.credentialJSON : ""

        case .database(let payload, _):
            return field == .linkString ? payload.linkString : ""

        case .sshKey(let payload, _):
            switch field {
            case .privateKey: return payload.privateKey
            case .passphrase: return payload.passphrase ?? ""
            default:          return ""
            }

        case .sslTlsCertificate(let payload, _):
            switch field {
            case .certificate:      return payload.certificate
            case .sslPrivateKey:    return payload.privateKey
            case .certificateChain: return payload.certificateChain ?? ""
            default:                return ""
            }

        case .environmentVariableSet(let payload):
            return field == .envContent ? payload.content : ""

        case .licenseKey(let payload, _):
            return field == .licenseKey ? payload.licenseKey : ""

        case .custom(let payload):
            return field == .value ? payload.value : ""
        }
    }
}
