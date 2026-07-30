// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 시크릿 감지 파이프라인 UseCase 구현체.
///
/// 감지 순서: `EnvSet` → `JSONCredential` → `PEM` → `DatabaseURL` → `PrefixRegex` → `JWT`.
/// 각 detector가 `nil`을 반환하면 다음 detector로 fall-through, non-nil을 반환하면 즉시 그 결과 반환.
/// 순서는 다중 매칭 가능성이 큰 컨테이너 포맷(env · JSON)이 개별 값 매칭보다 먼저 판별되도록 정렬.
public struct DetectSecretUseCaseImpl: DetectSecretUseCase, DetectorContext {
    private let detectors: [any SecretDetector]

    public init(repository: any SecretPatternRepository = BundledSecretPatternRepository()) {
        self.detectors = [
            EnvSetDetector(),
            JSONCredentialDetector(),
            PEMDetector(rules: repository.pemHeaders()),
            DatabaseURLDetector(schemes: repository.databaseSchemes()),
            PrefixRegexDetector(
                prefixRules: repository.prefixRules(),
                regexRules: repository.regexRules()
            ),
            JWTDetector(),
        ]
    }

    public func execute(value: SensitiveString) -> DetectionResult {
        value.withUnsafeAccess { raw in
            let normalized = InputNormalizer.normalize(raw)
            guard !normalized.isEmpty else { return .none }

            let wrapped = SensitiveString(normalized)
            for detector in detectors {
                if let result = detector.detect(wrapped, context: self) {
                    return result
                }
            }
            return .none
        }
    }

    /// `DetectorContext` 채택. `EnvSetDetector`가 각 KEY의 VALUE에 대해 재귀적으로 파이프라인을 호출할 수 있게 한다.
    public func detect(_ value: SensitiveString) -> DetectionResult {
        execute(value: value)
    }
}
