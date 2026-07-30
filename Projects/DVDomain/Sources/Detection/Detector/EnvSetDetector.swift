// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 여러 줄 KEY=VALUE 형태(`.env` 파일 등) 감지. 각 VALUE는 파이프라인을 재귀 호출해 세부 감지.
///
/// 현재는 파싱 로직 미구현. 파이프라인에서 항상 fall-through.
struct EnvSetDetector: SecretDetector {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult? {
        nil
    }
}
