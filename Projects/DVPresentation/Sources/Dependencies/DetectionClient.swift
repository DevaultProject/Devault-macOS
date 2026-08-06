// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation

/// 시크릿 감지 엔진을 Presentation layer에 노출하는 TCA 의존성.
/// 동기 순수 함수이므로 async/throws 없음.
@DependencyClient
public struct DetectionClient: Sendable {
    /// 시크릿 원문으로 서비스 후보 + 부가 메타데이터 감지. 매칭 없으면 `DetectionResult.none`.
    public var detect: @Sendable (SensitiveString) -> DetectionResult = { _ in .none }
}

extension DetectionClient: TestDependencyKey {
    public static let testValue = DetectionClient()

    public static let previewValue = DetectionClient(
        detect: { _ in .none }
    )
}

extension DependencyValues {
    public var detectionClient: DetectionClient {
        get { self[DetectionClient.self] }
        set { self[DetectionClient.self] = newValue }
    }
}
