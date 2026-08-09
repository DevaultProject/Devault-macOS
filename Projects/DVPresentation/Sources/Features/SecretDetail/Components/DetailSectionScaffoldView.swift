// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// 조회 화면 섹션들의 공통 bookend — 생성 화면 `FormSectionScaffold`의 read-only 대응.
///
/// Name 최상단, Memo 최하단, 행 간격을 타입 시스템으로 강제하고 중간 rows는 caller가
/// `@ViewBuilder content`로 자유 구성한다.
///
/// **공통 페어 행(Project / Services / Expire Date / Environment)을 여기에 넣지 않는다.**
/// 구성이 타입마다 다르기 때문이다 — `SSHKey`·`SSLTLSCert`·`EnvSet`은 `Project | Environment`이고
/// Services·Expire Date 행이 없으며, `ServiceAccount`는 Expire Date가 단독 행이고,
/// `LicenseKey`는 Environment 자리에 License Tier가 온다. 생성 화면도 같은 이유로
/// 스캐폴드에 넣지 않고 각 섹션이 조립한다.
///
/// 복호화 전에는 호출부가 이 스캐폴드를 아예 렌더하지 않는다(`SecretDetailView` 참고) —
/// 값이 채워진 필드와 빈 필드가 섞이면 어디까지가 복호화된 정보인지 구분되지 않기 때문이다.
struct DetailSectionScaffoldView<Content: View>: View {

    let secret: Secret

    private let content: () -> Content

    @Environment(\.formLayout) private var layout

    init(
        secret: Secret,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.secret = secret
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: layout.rowSpacing) {
            DetailReadOnlyFieldView(
                label: .module("Name"),
                value: secret.name
            )

            content()

            DetailReadOnlyFieldView(
                label: .module("Memo"),
                value: secret.memoDisplayText
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Detail 컬럼 최소폭 (420)") {
    ScrollView {
        DetailSectionScaffoldView(secret: [Secret].previewSubTypeMatrix[0]) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: "ghp_1234567890abcdef",
                isSensitive: true,
                isCopyable: true
            )
        }
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("2열 폼 (dual)") {
    ScrollView {
        DetailSectionScaffoldView(secret: [Secret].previewSubTypeMatrix[0]) {
            DetailReadOnlyFieldView(
                label: .module("Value"),
                value: "ghp_1234567890abcdef",
                isSensitive: true,
                isCopyable: true
            )
        }
        .padding(20)
    }
    .formLayout(.dual)
    .previewWidth(.wide)
}

/// Memo가 nil이면 `DVTextContainer`의 Empty 상태(박스만)로 표시된다.
#Preview("Memo 비어있음") {
    ScrollView {
        DetailSectionScaffoldView(secret: [Secret].previewSubTypeMatrix[1]) {
            DetailReadOnlyFieldView(label: .module("Value"), value: "")
        }
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
