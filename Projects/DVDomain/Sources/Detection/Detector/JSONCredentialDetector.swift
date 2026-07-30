// Copyright © 2026 Devault. All rights reserved

import Foundation

/// JSON credential 문서 감지. `JSONSerialization`으로 파싱한 뒤 구조적 힌트로 종류를 판별한다.
///
/// 판별 우선순위:
/// 1. `type == "service_account"` → GCP · (본문에 `firebase` 포함 시) Firebase Service Account
/// 2. `installed` 또는 `web` 하위 오브젝트 → Google OAuth Client
/// 3. 최상위 또는 하위 오브젝트에 `aws_access_key_id` → AWS Credentials
/// 4. 최상위에 `client_id` + `client_secret` → Generic OAuth Client Credentials
struct JSONCredentialDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            guard let data = raw.data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            if let result = detectServiceAccount(root: root, raw: raw) { return result }
            if let result = detectGoogleOAuthClient(root: root) { return result }
            if let result = detectAWSCredentials(root: root) { return result }
            if let result = detectGenericOAuth(root: root) { return result }
            return nil
        }
    }

    private func detectServiceAccount(root: [String: Any], raw: String) -> DetectionResult? {
        guard (root["type"] as? String) == "service_account" else { return nil }
        let isFirebase = raw.lowercased().contains("firebase")
        let kind: DetectedMetadata.JSONCredentialInfo.Kind = isFirebase
            ? .firebaseServiceAccount
            : .gcpServiceAccount
        let service = isFirebase ? "Firebase Service Account" : "GCP Service Account"
        let info = DetectedMetadata.JSONCredentialInfo(
            kind: kind,
            projectId: root["project_id"] as? String,
            clientEmail: root["client_email"] as? String
        )
        return DetectionResult(
            candidates: [.init(service: service, displayLabel: service, confidence: .high)],
            metadata: .json(info)
        )
    }

    private func detectGoogleOAuthClient(root: [String: Any]) -> DetectionResult? {
        for key in ["installed", "web"] {
            guard let sub = root[key] as? [String: Any],
                  let clientId = sub["client_id"] as? String else { continue }
            let info = DetectedMetadata.JSONCredentialInfo(
                kind: .googleOAuthClient,
                clientId: clientId,
                redirectUris: sub["redirect_uris"] as? [String] ?? []
            )
            return DetectionResult(
                candidates: [.init(
                    service: "Google OAuth Client",
                    displayLabel: "Google OAuth Client",
                    confidence: .high
                )],
                metadata: .json(info)
            )
        }
        return nil
    }

    private func detectAWSCredentials(root: [String: Any]) -> DetectionResult? {
        guard hasKey("aws_access_key_id", in: root) else { return nil }
        let info = DetectedMetadata.JSONCredentialInfo(kind: .awsCredentials)
        return DetectionResult(
            candidates: [.init(
                service: "AWS Credentials",
                displayLabel: "AWS Credentials",
                confidence: .high
            )],
            metadata: .json(info)
        )
    }

    private func detectGenericOAuth(root: [String: Any]) -> DetectionResult? {
        guard let clientId = root["client_id"] as? String,
              root["client_secret"] != nil else { return nil }
        let info = DetectedMetadata.JSONCredentialInfo(kind: .generic, clientId: clientId)
        return DetectionResult(
            candidates: [.init(
                service: "OAuth Client Credentials",
                displayLabel: "OAuth Client Credentials",
                confidence: .medium
            )],
            metadata: .json(info)
        )
    }

    /// 최상위에 있는지, 또는 한 단계 아래 dict에 있는지 확인.
    private func hasKey(_ target: String, in root: [String: Any]) -> Bool {
        if root[target] != nil { return true }
        for value in root.values {
            if let sub = value as? [String: Any], sub[target] != nil { return true }
        }
        return false
    }
}
