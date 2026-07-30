// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 시크릿 원문(예: paste 이벤트) → 서비스 후보 + 부가 메타데이터.
///
/// - Presentation layer는 반드시 `SensitiveString`으로 감싼 값을 전달. Raw String은 결과에 담기지 않는다.
/// - 매칭 없으면 `DetectionResult.none`.
public protocol DetectSecretUseCase: Sendable {
    func execute(value: SensitiveString) -> DetectionResult
}
