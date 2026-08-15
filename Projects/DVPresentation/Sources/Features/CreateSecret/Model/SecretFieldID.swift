// Copyright © 2026 Devault. All rights reserved

/// 시크릿 입력·표시 필드의 식별자.
///
/// 생성 화면은 검증 오류와 자동 감지 결과를 이 키로 붙이고, 조회 화면은 필드마다 마스킹 상태를
/// 이 키로 들고 있다. 두 화면이 같은 필드를 가리키므로 식별자를 공유한다.
///
/// `SecretMetaFields` 안에 중첩돼 있었으나 그 타입이 internal이라 public API(`SecretDetailFeature.Action`)에
/// 실을 수 없어 밖으로 올렸다. 기존 표기는 `SecretMetaFields.FieldID` 별칭으로 유지된다.
///
/// `value`는 apiKeyToken과 custom이 함께 쓴다 — 한 화면에 한 타입만 뜨므로 충돌하지 않는다.
public enum SecretFieldID: Hashable, Sendable {
    case name
    case value
    case clientId
    case clientSecret
    case credentialJSON
    case linkString
    case privateKey
    case certificate
    case sslPrivateKey
    case envContent
    case licenseKey

    // 생성 화면에서는 검증·감지 대상이 아니라 쓰이지 않는다(둘 다 필수 입력이 아니다).
    // 조회 화면이 payload 필드마다 마스킹 상태를 들고 있어야 해서 식별자가 필요하다.
    case certificateChain
    case passphrase
}
