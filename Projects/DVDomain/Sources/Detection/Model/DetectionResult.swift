// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct DetectionResult: Equatable, Sendable {
    /// 매칭된 서비스 후보들 (chip UI에 노출)
    public var candidates: [ServiceCandidate]
    /// 파싱된 부가 메타데이터 (form auto-fill용)
    public var metadata: DetectedMetadata?
    /// .env 세트일 때 각 KEY별 재귀 감지 결과
    public var subDetections: [SubDetection]

    public init(
        candidates: [ServiceCandidate] = [],
        metadata: DetectedMetadata? = nil,
        subDetections: [SubDetection] = []
    ) {
        self.candidates = candidates
        self.metadata = metadata
        self.subDetections = subDetections
    }

    public static let none = DetectionResult()
}
