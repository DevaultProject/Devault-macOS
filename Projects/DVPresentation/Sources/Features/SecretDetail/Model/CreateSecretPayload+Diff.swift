// Copyright © 2026 Devault. All rights reserved

// MARK: - payload / metadata dirty 판정

extension CreateSecretPayload {

    /// baseline 대비 payload 성분과 metadata 성분이 각각 바뀌었는지 판정한다.
    ///
    /// **폼 필드가 아니라 매핑 결과를 비교한다.** 어떤 폼 필드가 payload로 가고 어떤 것이 metadata로
    /// 가는지는 `SecretMetaFields+Mapping`만 알아야 한다. 폼 쪽에서 비교하면 그 규칙을 아는 코드가
    /// 한 벌 더 생기고, 매핑이 바뀔 때 조용히 어긋난다.
    ///
    /// 서브타입은 수정 화면에서 바뀌지 않으므로(payload 스키마 자체가 달라져 수정이 아니라 재생성이다)
    /// 두 값은 항상 같은 case다.
    static func diff(
        baseline: CreateSecretPayload,
        updated: CreateSecretPayload
    ) -> (payload: Bool, metadata: Bool) {
        switch (baseline, updated) {
        case (.apiKey(let old, let oldMeta), .apiKey(let new, let newMeta)),
             (.accessToken(let old, let oldMeta), .accessToken(let new, let newMeta)),
             (.webhookSecret(let old, let oldMeta), .webhookSecret(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.oauthClient(let old, let oldMeta), .oauthClient(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.serviceAccount(let old, let oldMeta), .serviceAccount(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.database(let old, let oldMeta), .database(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.sshKey(let old, let oldMeta), .sshKey(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.sslTlsCertificate(let old, let oldMeta), .sslTlsCertificate(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        case (.licenseKey(let old, let oldMeta), .licenseKey(let new, let newMeta)):
            return (old != new, oldMeta != newMeta)

        // metadata 스키마가 없는 타입이라 metadata는 언제나 변경 없음이다.
        case (.environmentVariableSet(let old), .environmentVariableSet(let new)):
            return (old != new, false)

        case (.custom(let old), .custom(let new)):
            return (old != new, false)

        // 서브타입이 고정이므로 도달할 수 없다. 도달했다면 매핑 버그이고, 그때 변경 없음으로
        // 처리하면 사용자 입력이 조용히 사라진다 — 보수적으로 둘 다 다시 쓴다.
        default:
            // payload를 그대로 보간하면 연관값의 평문(API 키·개인키·클라이언트 시크릿)이
            // 문자열에 실린다. `assertionFailure` 메시지는 Debug 크래시 리포트에 남으므로
            // 리포트가 수집·공유되는 순간 시크릿이 함께 나간다. 진단에 필요한 것은 어느 case끼리
            // 어긋났는지뿐이라 값 없는 이름만 남긴다.
            assertionFailure("서브타입이 다른 payload 조합: \(baseline.caseName) → \(updated.caseName)")
            return (true, true)
        }
    }

    /// `diff` 결과와 최종 payload로 저장 시 다시 쓸 대상을 정한다.
    ///
    /// metadata가 바뀌었는데 값이 `nil`이면 **지우는 것**이다. 마지막 남은 metadata 필드를 사용자가
    /// 비운 경우이고, 그대로 두면 지운 값이 저장소에 남아 다시 열 때 되살아난다.
    func contentChange(comparedTo baseline: CreateSecretPayload) -> SecretContentChange {
        let (payloadChanged, metadataChanged) = Self.diff(baseline: baseline, updated: self)
        let clearsMetadata = metadataChanged && !hasMetadata

        switch (payloadChanged, metadataChanged, clearsMetadata) {
        case (false, false, _):      return .none
        case (true, false, _):       return .payload(self)
        case (false, true, false):   return .metadata(self)
        case (false, true, true):    return .metadataCleared
        case (true, true, false):    return .payloadAndMetadata(self)
        case (true, true, true):     return .payloadAndMetadataCleared(self)
        }
    }

    /// metadata 성분이 실제로 실려 있는지. 스키마가 없는 타입은 언제나 `false`다.
    private var hasMetadata: Bool {
        switch self {
        case .apiKey(_, let metadata),
             .accessToken(_, let metadata),
             .webhookSecret(_, let metadata):
            return metadata != nil
        case .oauthClient(_, let metadata):       return metadata != nil
        case .serviceAccount(_, let metadata):    return metadata != nil
        case .database(_, let metadata):          return metadata != nil
        case .sshKey(_, let metadata):            return metadata != nil
        case .sslTlsCertificate(_, let metadata): return metadata != nil
        case .licenseKey(_, let metadata):        return metadata != nil
        case .environmentVariableSet, .custom:    return false
        }
    }

    /// 값을 뺀 case 이름. **진단 문자열에는 이것만 쓴다** — payload를 그대로 보간하면
    /// 연관값의 평문 시크릿이 로그·크래시 리포트로 새어 나간다.
    ///
    /// `String(describing:)`이나 `Mirror`로도 이름을 얻을 수 있지만 둘 다 값에 닿는다.
    /// 여기서 명시적으로 나열하면 값이 실릴 길 자체가 없고, case가 늘면 컴파일러가 알려준다.
    var caseName: String {
        switch self {
        case .apiKey:                 return "apiKey"
        case .accessToken:            return "accessToken"
        case .webhookSecret:          return "webhookSecret"
        case .oauthClient:            return "oauthClient"
        case .serviceAccount:         return "serviceAccount"
        case .database:               return "database"
        case .sshKey:                 return "sshKey"
        case .sslTlsCertificate:      return "sslTlsCertificate"
        case .environmentVariableSet: return "environmentVariableSet"
        case .licenseKey:             return "licenseKey"
        case .custom:                 return "custom"
        }
    }
}
