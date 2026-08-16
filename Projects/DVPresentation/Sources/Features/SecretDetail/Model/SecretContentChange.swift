// Copyright © 2026 Devault. All rights reserved

// MARK: - SecretContentChange

/// 수정 저장에서 **다시 쓸 대상**. Presentation의 dirty 판정 결과이고, Live 조립이 이 case를 보고
/// `PatchSecretUseCase`의 overload 중 하나를 고른다.
///
/// 바뀌지 않은 것을 싣지 않는 이유가 case를 나눈 이유다.
/// - **payload**: 다시 쓰지 않으면 재암호화를 건너뛰어 `keyTag`·`schemaVersion`이 보존되고,
///   평문이 필요 없이 암호화 경로를 타지 않는다.
/// - **metadata**: `.unchanged`로 두면 저장된 값이 그대로 남는다. UI에 입력 경로가 없는 필드를
///   지키는 1차 방어선이고, 값이 실제로 바뀐 경우에만
///   `SecretMetaFields.toCreateSecretPayload(preserving:)`의 병합이 필요해진다.
///
/// `payload`·`metadata`를 독립된 두 플래그가 아니라 하나의 enum으로 둔 것은 **표현할 수 없는 상태를
/// 만들지 않기 위해서**다 — "쓰지 않는데 평문은 실려 있는" 조합이 생기지 않는다.
public enum SecretContentChange: Equatable, Sendable {

    /// 공통 필드·프로젝트 연결만 바뀌었다. payload·metadata 모두 건드리지 않는다.
    case none

    /// payload만 바뀌었다.
    case payload(CreateSecretPayload)

    /// metadata만 바뀌었다.
    case metadata(CreateSecretPayload)

    /// payload와 metadata가 함께 바뀌었다.
    case payloadAndMetadata(CreateSecretPayload)

    /// metadata를 지운다 — 마지막으로 남아 있던 metadata 필드를 사용자가 비운 경우다.
    ///
    /// 별도 case가 필요한 이유는 도메인의 metadata overload가 **값을 요구해 `nil`을 표현할 수 없기**
    /// 때문이다. 이 경우 metadata 없는 overload에 `SecretPatch.metadata = .set(nil)`을 실어 보낸다.
    /// 그냥 ``none``으로 처리하면 지운 값이 DB에 남아 다시 열 때 되살아난다.
    case metadataCleared

    /// payload가 바뀌면서 metadata는 비워졌다. (예: API Key 값을 고치고 Scope를 지운 경우)
    case payloadAndMetadataCleared(CreateSecretPayload)
}

// MARK: - Dispatch helpers

/// Live 조립이 overload를 고를 때 쓴다. case를 늘리면 여기 네 프로퍼티가 컴파일 에러로 누락을 잡는다.
extension SecretContentChange {

    /// 다시 쓸 값의 출처. 쓸 것이 없으면 `nil`이고, 그때는 평문이 Client 경계를 넘지 않는다.
    public var content: CreateSecretPayload? {
        switch self {
        case .none, .metadataCleared:
            return nil
        case .payload(let content),
             .metadata(let content),
             .payloadAndMetadata(let content),
             .payloadAndMetadataCleared(let content):
            return content
        }
    }

    /// payload를 다시 암호화해 저장할지.
    public var writesPayload: Bool {
        switch self {
        case .payload, .payloadAndMetadata, .payloadAndMetadataCleared:
            return true
        case .none, .metadata, .metadataCleared:
            return false
        }
    }

    /// metadata를 새 값으로 덮어쓸지.
    public var writesMetadata: Bool {
        switch self {
        case .metadata, .payloadAndMetadata:
            return true
        case .none, .payload, .metadataCleared, .payloadAndMetadataCleared:
            return false
        }
    }

    /// metadata 레코드를 지울지. ``writesMetadata``와 동시에 참이 되지 않는다.
    public var clearsMetadata: Bool {
        switch self {
        case .metadataCleared, .payloadAndMetadataCleared:
            return true
        case .none, .payload, .metadata, .payloadAndMetadata:
            return false
        }
    }
}
