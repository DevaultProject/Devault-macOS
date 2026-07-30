// Copyright © 2026 Devault. All rights reserved

import Foundation

/// JSON credential 문서 감지 (GCP service account · Firebase · Google OAuth client · AWS credentials 등).
///
/// 현재는 파싱 로직 미구현. 파이프라인에서 항상 fall-through.
struct JSONCredentialDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        nil
    }
}
