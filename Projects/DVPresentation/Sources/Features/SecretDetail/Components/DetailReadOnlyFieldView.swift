// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// 조회 모드 전용 읽기 전용 필드 (`DVLabeledField` + 값 컨테이너).
///
/// 값을 변경하는 컨트롤을 렌더하지 않는다 — 마스킹 토글과 복사는 표시·클립보드에만
/// 영향을 주며 `value`를 바꾸지 않는다. 조회 모드 뷰 트리에 인터랙티브 입력 컨트롤이
/// 섞이지 않도록 값 바인딩 파라미터를 두지 않는다.
///
/// 마스킹(`isSensitive`)·복사(`isCopyable`) 여부는 서브타입·필드별로 다르므로 판정 규칙을
/// 이 컴포넌트가 갖지 않는다. 각 타입 섹션이 호출 시점에 직접 지정한다.
///
/// `FormLayout` Environment를 읽어 자기 컴포넌트 사이즈를 결정 —
/// `LabeledTextFieldView`와 동일 규칙이므로 조회/수정 모드의 필드 폭이 일치한다.
///
/// 생성 화면의 `LabeledTextFieldView`(`DVLabeledField` + `DVTextField`)에 1:1 대응하는
/// read-only 컴포넌트다.
///
/// ## 여러 줄 표시
///
/// 컨테이너를 갈아끼우지 않는다. `DVTextContainer` 하나가 줄바꿈하며 내용만큼 자라므로,
/// 개행이 있는 값(PEM, JSON, `KEY=value` 목록)도 긴 한 줄 값(연결 문자열, public key)도
/// 잘리거나 가로 스크롤 없이 전부 보인다.
///
/// 값으로 컨테이너를 판정하던 방식을 버린 이유는 두 가지다. 조회 화면은 값을 확인할 유일한
/// 수단이라 어느 쪽이든 다 보여야 하고, 민감 필드는 복호화 전에 값이 없어 판정 자체가 불가능하다
/// (마스킹 상태에서 한 줄로 그렸다가 reveal 후 여러 줄로 바뀌면 높이가 튄다).
///
/// ## 빈 값 — 출처에 따라 갈린다
///
/// **민감 필드(`isSensitive`)는 빈 값 예외가 없다.** 값이 payload에 암호화돼 있어 복호화 전에는
/// 값도 길이도 알 수 없고, 따라서 비었는지 판단할 수 없다. 항상 마스킹하고 두 버튼을 모두 노출한다.
/// 마스킹이 값의 **존재 여부까지** 가리는 셈이라 보장이 더 강하다.
///
/// **평문 필드는 빈 값이면** `isCopyable`을 무시하고 액세서리 없는 일반 컨테이너로 그린다.
/// metadata·secret에서 오는 값이라 그릴 때 이미 알고 있고, 빈 문자열을 클립보드에 쓰는 버튼은
/// 의미가 없다. Optional 필드가 미입력이면 흔히 발생한다 — 생성 화면은 `renewCommand` 같은 값이
/// 비면 metadata 자체를 저장하지 않으므로 조회에서 빈 문자열로 들어온다.
///
/// ## 인증·복호화는 이 컴포넌트가 하지 않는다
///
/// 눈·복사 버튼은 **액션을 주입받는다**. 마스킹 해제에는 인증이 필요하고, 값 자체가 복호화되어야
/// 하며, 복사는 30초 자동 정리·반복 감지 정책을 타야 한다 — 전부 Feature가 UseCase로 수행할 일이다.
/// `isRevealed`도 로컬 State가 아니라 주입받는다. 복호화가 payload 단위라 필드 하나의 사정으로
/// 결정할 수 없기 때문이다.
struct DetailReadOnlyFieldView: View {

    let label: String
    /// 복호화 전에는 빈 문자열이 들어온다. 마스킹 중에는 화면에 쓰이지 않는다.
    let value: String
    /// 마스킹 + 눈 토글 노출. 빈 값이어도 유지된다 (위 "빈 값" 규칙).
    var isSensitive: Bool = false
    /// 복사 버튼 노출. 평문 필드에서만 빈 값일 때 무시된다.
    var isCopyable: Bool = false
    /// 이 필드의 식별자. 눈·복사 동작을 Feature에 전달할 때 쓴다.
    /// payload에서 오는 민감 필드만 갖는다 — 평문 필드는 복사 외에 할 일이 없다.
    var field: SecretFieldID?
    var sizeMode: FormSlotSize = .fullWidth

    @Environment(\.formLayout) private var layout
    @Environment(\.detailFieldActions) private var actions

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    /// 마스킹 표시. **길이를 원문에서 끌어오지 않는다** — 복호화 전에는 알 수 없고, reveal 뒤에
    /// 실제 길이로 바뀌면 마스킹이 값의 크기를 흘린다. 항상 같은 개수라 유출 경로가 없다.
    private static let maskedPlaceholder = String(repeating: "•", count: 12)

    /// 복사 버튼 노출. 민감 필드는 복호화 전이라 비었는지 알 수 없어 빈 값 예외를 적용할 수 없다.
    private var showsCopyButton: Bool {
        isCopyable && (isSensitive || !value.isEmpty)
    }

    /// 눈 토글 노출. 민감 필드면 항상 — 가려진 값이 비어 있는지도 알려주지 않는다.
    private var showsRevealToggle: Bool { isSensitive }

    var body: some View {
        DVLabeledField(label, size: size) {
            valueContainer
        }
    }
}

// MARK: - Subviews

extension DetailReadOnlyFieldView {

    /// 액세서리가 하나라도 붙는지. 하나도 없으면 좌우 대칭 padding을 주는 편의 init을 써야 한다 —
    /// 빈 액세서리 뷰를 넘기면 컨테이너가 우측 padding을 4pt로 줄여 텍스트가 한쪽으로 치우친다.
    private var hasAccessories: Bool { showsRevealToggle || showsCopyButton }

    /// 화면에 그릴 문자열. 마스킹 중이면 고정 placeholder, 아니면 원문.
    /// 복사는 이 값을 쓰지 않는다 — 호출부가 원문을 클립보드에 넣는다.
    private var displayedValue: String {
        isSensitive && !actions.isRevealed(field) ? Self.maskedPlaceholder : value
    }

    @ViewBuilder
    private var valueContainer: some View {
        if hasAccessories {
            DVTextContainer(displayedValue, size: size) { accessoryButtons }
        } else {
            DVTextContainer(displayedValue, size: size)
        }
    }

    /// 복사·마스킹 토글 버튼. 한 줄/여러 줄 컨테이너 어디에 붙어도 같은 모습이어야 하므로
    /// 컨테이너 선택과 분리해 한 곳에서 만든다.
    @ViewBuilder
    private var accessoryButtons: some View {
        HStack(spacing: 10) {
            if showsCopyButton {
                Button {
                    field.map(actions.onCopy)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
            if showsRevealToggle {
                Button {
                    field.map(actions.onToggleReveal)
                } label: {
                    Image(systemName: actions.isRevealed(field) ? "eye.slash" : "eye")
                }
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(Color.dv(.gray900))
        .buttonStyle(.plain)
    }

}

// MARK: - Preview

#if DEBUG

#Preview("Plain · Full-width · Dual") {
    DetailReadOnlyFieldView(
        label: .module("Service"),
        value: "GitHub"
    )
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Plain · Full-width · Single") {
    DetailReadOnlyFieldView(
        label: .module("Service"),
        value: "GitHub"
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

#Preview("Sensitive") {
    DetailReadOnlyFieldView(
        label: .module("Value"),
        value: "ghp_1234567890abcdef",
        isSensitive: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

#Preview("Copyable") {
    DetailReadOnlyFieldView(
        label: .module("Client ID"),
        value: "1234567890-abcdefg.apps.googleusercontent.com",
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

#Preview("Sensitive + Copyable") {
    DetailReadOnlyFieldView(
        label: .module("Client Secret"),
        value: "GOCSPX-1a2b3c4d5e6f7g8h9i0j",
        isSensitive: true,
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 민감 필드는 빈 값이어도 마스킹과 두 버튼을 유지한다 — 복호화 전이라 비었는지 알 수 없다.
/// 복호화 전 상태(`value: ""`, `isRevealed: false`)가 조회 화면 진입 직후의 모습이다.
#Preview("Sensitive · 복호화 전") {
    DetailReadOnlyFieldView(
        label: .module("PassPhrase"),
        value: "",
        isSensitive: true,
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 평문 필드는 빈 값이면 액세서리 없이 일반 컨테이너가 된다.
/// 버튼이 하나도 보이지 않아야 하고 텍스트 좌우 padding이 대칭이어야 한다.
#Preview("Plain · 빈 값") {
    DetailReadOnlyFieldView(
        label: .module("Renew Command"),
        value: "",
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

#Preview("Paired · Dual") {
    AdaptiveFieldRow {
        DetailReadOnlyFieldView(
            label: .module("Environment"),
            value: "production",
            sizeMode: .paired
        )
    } right: {
        DetailReadOnlyFieldView(
            label: .module("Expire Date"),
            value: "2026-12-31",
            sizeMode: .paired
        )
    }
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Paired · Single") {
    AdaptiveFieldRow {
        DetailReadOnlyFieldView(
            label: .module("Environment"),
            value: "production",
            sizeMode: .paired
        )
    } right: {
        DetailReadOnlyFieldView(
            label: .module("Expire Date"),
            value: "2026-12-31",
            sizeMode: .paired
        )
    }
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 개행 없는 값이 컨테이너 폭을 넘으면 `DVTextContainer`가 가로 스크롤로 처리한다.
#Preview("Overflow · 가로 스크롤") {
    DetailReadOnlyFieldView(
        label: .module("Link String"),
        value: "postgresql://admin:verylongpassword@db.internal.example.com:5432/production_database?sslmode=require",
        isSensitive: true,
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 개행이 있으면 `DVMultilineTextContainer`로 전환되어 모든 줄이 보인다.
#Preview("Multiline") {
    DetailReadOnlyFieldView(
        label: .module("envSet List"),
        value: """
        DATABASE_URL=postgres://user:pass@localhost:5432/mydb
        OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        SECRET_KEY=abc123
        """
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 마스킹은 줄 단위로 적용되어 줄 구조가 유지된다.
#Preview("Multiline · Sensitive") {
    DetailReadOnlyFieldView(
        label: .module("envSet List"),
        value: """
        DATABASE_URL=postgres://user:pass@localhost:5432/mydb
        OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        SECRET_KEY=abc123
        """,
        isSensitive: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

/// 높이를 넘는 여러 줄 값 — 세로 스크롤로 확인하고, 복사 버튼은 원문 전체를 넣는다.
#Preview("Multiline · Copyable") {
    DetailReadOnlyFieldView(
        label: .module("Private Key"),
        // 개인키 형태의 문자열은 쓰지 않는다 — 가짜여도 시크릿 스캐너가 매번 탐지 결과를 올린다.
        // 이 프리뷰가 확인하려는 건 값의 진위가 아니라 높이 초과 시의 스크롤·복사 동작이다.
        value: """
        PREVIEW PLACEHOLDER — 실제 키가 아니다
        여러 줄 값이 고정 높이를 넘겼을 때의 세로 스크롤을 확인하기 위한 자리 채움 텍스트
        세 번째 줄
        네 번째 줄
        다섯 번째 줄 — 여기서 100pt를 넘겨 스크롤 인디케이터가 보인다
        """,
        isCopyable: true
    )
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(.narrow)
}

#endif
