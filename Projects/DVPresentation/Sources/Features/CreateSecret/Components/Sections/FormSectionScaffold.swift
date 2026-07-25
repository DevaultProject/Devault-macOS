// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// CreateSecret SectionView들의 공통 bookend — `NameFieldView` 최상단, `MemoFieldView` 최하단,
/// 16pt 간격 · `.frame(maxWidth: .infinity, alignment: .leading)` 컨테이너를 타입 시스템으로 강제.
/// 중간 rows는 caller가 `@ViewBuilder content`로 자유 구성.
struct FormSectionScaffold<Content: View>: View {

    @Binding var name: String
    let nameWarning: String?
    @Binding var memo: String
    let content: () -> Content

    init(
        name: Binding<String>,
        nameWarning: String?,
        memo: Binding<String>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._name = name
        self.nameWarning = nameWarning
        self._memo = memo
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NameFieldView(name: $name, warning: nameWarning)
            content()
            MemoFieldView(memo: $memo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
