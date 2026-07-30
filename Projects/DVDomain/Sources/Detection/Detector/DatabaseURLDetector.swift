// Copyright © 2026 Devault. All rights reserved

import Foundation

/// URL 형태 데이터베이스 · 메시지 큐 · 캐시 접속 문자열 감지.
///
/// 등록된 scheme(`postgres` · `mongodb+srv` 등)에만 매칭. host suffix로 관리형 서비스 후보를 함께 부여.
struct DatabaseURLDetector: SecretDetector {
    let schemes: [DatabaseSchemeRule]

    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        value.withUnsafeAccess { raw in
            if let result = detectAsURL(raw) { return result }
            return detectAsAzureConnectionString(raw)
        }
    }

    /// URL 파싱이 실패하는 Azure 스타일 `Key=Value;` 커넥션 문자열 매칭. metadata는 부여하지 않는다.
    private func detectAsAzureConnectionString(_ raw: String) -> DetectionResult? {
        if raw.contains("DefaultEndpointsProtocol=") && raw.contains("AccountName=") {
            return azureResult(service: "Azure Storage", label: "Azure Storage Connection String")
        }
        if raw.contains("Endpoint=sb://") {
            return azureResult(service: "Azure Service Bus", label: "Azure Service Bus Connection String")
        }
        if raw.contains("Server=") && raw.contains("Database=") {
            return azureResult(service: "Azure SQL", label: "Azure SQL Connection String")
        }
        return nil
    }

    private func azureResult(service: String, label: String) -> DetectionResult {
        DetectionResult(candidates: [.init(service: service, displayLabel: label, confidence: .high)])
    }

    private func detectAsURL(_ raw: String) -> DetectionResult? {
        guard let comps = URLComponents(string: raw),
              let scheme = comps.scheme?.lowercased(),
              let rule = schemes.first(where: { $0.scheme == scheme }) else {
            return nil
        }

        let host = comps.host
        let port = comps.port ?? rule.defaultPort
        let databaseName: String? = {
            let path = comps.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return path.isEmpty ? nil : path
        }()

        let info = DetectedMetadata.DatabaseInfo(
            scheme: scheme,
            host: host,
            port: port,
            databaseName: databaseName,
            username: comps.user
        )

        let candidates = hostCandidates(for: host)
        return DetectionResult(candidates: candidates, metadata: .database(info))
    }

    private func hostCandidates(for host: String?) -> [ServiceCandidate] {
        guard let host = host?.lowercased() else { return [] }
        if host == "neon.tech" || host.hasSuffix(".neon.tech") {
            return [.init(service: "Neon", displayLabel: "Neon Postgres", confidence: .high)]
        }
        if host.hasSuffix(".supabase.co") {
            return [.init(service: "Supabase DB", displayLabel: "Supabase Postgres", confidence: .high)]
        }
        return []
    }
}
