// Copyright © 2026 Devault. All rights reserved

/// 시스템 클립보드(pasteboard) 입출력만 담당하는 서비스입니다.
public protocol ClipboardService: Sendable {
    /// 값을 pasteboard에 쓰고, 이후 변경 여부를 추적할 수 있는 changeCount를 반환한다.
    /// - Parameter value: pasteboard에 쓸 값
    /// - Returns: 쓰기 직후의 pasteboard changeCount
    func write(_ value: String) throws -> Int

    /// pasteboard의 changeCount가 주어진 값과 같으면(=그 사이 아무도 건드리지 않았으면) 정리하고 `true`를 반환한다.
    /// changeCount가 다르면(=다른 값이 복사됐으면) 아무것도 하지 않고 `false`를 반환한다.
    /// - Parameter changeCount: 비교 기준이 되는 이전 changeCount
    /// - Returns: 실제로 정리했는지 여부
    func clearIfUnchanged(from changeCount: Int) -> Bool
}
