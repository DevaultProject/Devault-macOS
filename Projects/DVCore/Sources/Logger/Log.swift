// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 앱 전역 기본 로거. `import DVCore` 후 `Log.debug("...")` 로 바로 쓴다.
///
/// ```swift
/// Log.info("앱 시작")
/// Log.error("복호화 실패", category: .crypto)
/// ```
///
/// 모듈을 별도 subsystem 으로 분리하려면 ``DVLogger`` 참고.
public enum Log: DVLogger {
    public static let subsystem = Bundle.main.bundleIdentifier ?? "com.devault"
}
