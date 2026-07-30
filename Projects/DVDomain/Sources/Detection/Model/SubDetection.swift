// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct SubDetection: Equatable, Sendable {
    /// .env 세트에서 파싱된 KEY 이름 (예: "OPENAI_API_KEY")
    public var key: String
    /// 해당 VALUE에 대한 재귀 감지 결과
    public var result: DetectionResult

    public init(key: String, result: DetectionResult) {
        self.key = key
        self.result = result
    }
}
