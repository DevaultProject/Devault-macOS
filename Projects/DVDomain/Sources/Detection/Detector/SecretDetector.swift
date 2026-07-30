// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 파이프라인의 각 감지 스텝.
///
/// - `nil`을 반환하면 다음 detector로 fall-through.
/// - non-nil을 반환하면 그 결과가 최종 결과 (뒤 detector는 실행 안 됨).
protocol SecretDetector: Sendable {
    func detect(_ value: SensitiveString, context: DetectorContext) -> DetectionResult?
}
