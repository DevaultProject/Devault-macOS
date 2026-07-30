// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Detector가 재귀적으로 파이프라인을 호출할 때 사용하는 콜백.
///
/// 주 사용처: `EnvSetDetector`가 각 KEY=VALUE의 VALUE에 대해 재귀 감지 필요.
/// UseCase Impl로의 직접 참조를 피하기 위한 seam.
protocol DetectorContext: Sendable {
    func detect(_ value: SensitiveString) -> DetectionResult
}
