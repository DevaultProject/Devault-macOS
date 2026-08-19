// Copyright © 2026 Devault. All rights reserved

import Foundation

/// Secret 날짜의 표시와 검색 매칭.
///
/// 표시(Presentation)와 검색(Data)이 서로 다른 모듈에서 맞물려야 해 DVCore에 둔다.
/// 규칙은 하나 — **검색은 보이는 대로 걸린다.**
///
/// 문자열이 아니라 `matches(searchKeyword:date:)`를 노출하는 것은 공백 정규화 계약을 안에
/// 가두기 위해서다. 호출자가 빠뜨리면 컴파일은 통과한 채 한국어에서만 검색이 안 된다.
public enum SecretDateFormatter {

    /// 화면에 보여줄 날짜. ko `2026. 4. 1.` / en `4/1/2026`
    public static func displayString(from date: Date) -> String {
        date.formatted(displayStyle)
    }

    /// 검색어가 이 날짜를 가리키는지. 로케일 숫자 날짜에는 공백이 섞여 양쪽에서 떼고 본다.
    public static func matches(searchKeyword keyword: String, date: Date) -> Bool {
        let compactKeyword = keyword.filter { !$0.isWhitespace }
        guard !compactKeyword.isEmpty else { return false }

        return compactDisplayString(from: date)
            .localizedCaseInsensitiveContains(compactKeyword)
    }

    private static func compactDisplayString(from date: Date) -> String {
        displayString(from: date).filter { !$0.isWhitespace }
    }

    /// 로케일을 비운 `DateFormatter`는 생성 시점의 `Locale.current`를 굳혀 앱 실행 중
    /// 언어를 바꿔도 따라오지 않는다. `FormatStyle`은 `.autoupdatingCurrent`를 쓴다.
    private static let displayStyle = Date.FormatStyle(date: .numeric, time: .omitted)
}
