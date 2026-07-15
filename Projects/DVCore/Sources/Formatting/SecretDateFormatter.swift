// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret 목록에서 날짜를 표시·검색할 때 쓰는 공통 포맷.
///
/// 표시(Presentation)와 검색(Data)이 서로 다른 모듈에서 동일한 문자열을
/// 만들어야 하므로, 두 모듈이 공통으로 의존하는 DVCore에 둔다.
/// 로케일에 따라 포맷이 바뀌면 검색어와 표시값이 어긋나므로 `en_US_POSIX`로 고정한다.
///
/// ```swift
/// SecretDateFormatter.string(from: secret.updatedAt) // "2026.04.01"
/// ```
public enum SecretDateFormatter {
    public static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
