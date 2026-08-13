// Copyright © 2026 Devault. All rights reserved

import AppKit
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
/// ## 한 줄 / 여러 줄 전환
///
/// 값에 개행이 있으면 `DVMultilineTextContainer`, 없으면 `DVTextContainer`로 렌더한다.
/// 조회 화면은 값을 확인할 유일한 수단이라 개행이 있는 값(PEM, JSON, `KEY=value` 목록)을
/// 한 줄 컨테이너에 넣으면 첫 줄 말고는 볼 방법이 없다.
///
/// 판정은 호출부 플래그가 아니라 **값 자체**로 한다 — 같은 필드라도 데이터에 따라 한 줄일 수도
/// 여러 줄일 수도 있다(한 줄로 저장된 `certificateChain`, 항목이 하나인 envSet 등).
///
/// ## 빈 값
///
/// 값이 비어 있으면 `isSensitive`·`isCopyable`을 **무시하고** 액세서리 없는 일반 컨테이너로 그린다.
/// 가릴 것도 복사할 것도 없어 두 버튼 모두 눌러도 아무 일이 일어나지 않기 때문이다.
///
/// Optional 필드가 미입력이면 흔히 발생한다 — 생성 화면은 `passphrase`·`renewCommand` 같은 값이
/// 비면 metadata 자체를 저장하지 않으므로 조회에서 빈 문자열로 들어온다.
struct DetailReadOnlyFieldView: View {

    let label: String
    let value: String
    /// 기본 마스킹 + 눈 토글. 값 변경이 아니라 표시 전환만 한다.
    /// 값이 비어 있으면 무시된다 (아래 "빈 값" 규칙).
    var isSensitive: Bool = false
    /// 복사 버튼 노출. 클립보드 쓰기는 이 컴포넌트가 수행한다.
    /// 값이 비어 있으면 무시된다 (아래 "빈 값" 규칙).
    var isCopyable: Bool = false
    var sizeMode: FormSlotSize = .fullWidth

    @Environment(\.formLayout) private var layout

    /// 마스킹 해제 여부. 로컬 표시 상태이므로 Feature State로 끌어올리지 않는다.
    @State private var isRevealed = false

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    /// `DVTextContainer(secured:isRevealed:size:)`의 `•` 반복 규칙을 **줄 단위로** 적용한 마스킹 값.
    ///
    /// 한 줄 값이면 결과가 그 규칙과 완전히 같다. 여러 줄 값은 전체를 하나의 `•` 덩어리로 만들지 않고
    /// 줄 구조를 유지한다 — 사용자가 마스킹 상태에서도 "3줄짜리 envSet"과 "30줄짜리 PEM"을 구분해
    /// 필드가 제대로 채워졌는지 확인할 수 있어야 하기 때문이다. 원문 길이는 한 줄 규칙에서도
    /// `•` 개수로 이미 드러나므로 줄 수 노출이 새로 만드는 유출은 아니다.
    ///
    /// 마스킹 전후로 줄 수가 같아 눈 토글 시 스크롤 위치와 박스 안 내용량이 튀지 않는 이점도 있다.
    private var maskedValue: String {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String(repeating: "•", count: $0.count) }
            .joined(separator: "\n")
    }

    /// 빈 값에는 복사 버튼을 달지 않는다 — 빈 문자열을 클립보드에 쓰는 버튼은 의미가 없다.
    private var showsCopyButton: Bool { isCopyable && !value.isEmpty }

    /// 빈 값에는 눈 토글도 달지 않는다 — 가릴 것이 없어 눌러도 아무 일이 일어나지 않는다.
    /// `isSensitive`를 그대로 쓰면 빈 필드에 동작하지 않는 버튼만 남고, 액세서리가 있다고
    /// 판정돼 컨테이너 우측 padding이 4pt로 줄어 텍스트 정렬까지 틀어진다.
    private var showsRevealToggle: Bool { isSensitive && !value.isEmpty }

    var body: some View {
        DVLabeledField(label, size: size) {
            valueContainer
        }
    }
}

// MARK: - Subviews

extension DetailReadOnlyFieldView {

    /// 값에 개행이 있는지. 여러 줄 컨테이너로 전환하는 유일한 판정 지점이다.
    private var isMultiline: Bool { value.contains("\n") }

    /// 액세서리가 하나라도 붙는지. 하나도 없으면 좌우 대칭 padding을 주는 편의 init을 써야 한다 —
    /// 빈 액세서리 뷰를 넘기면 컨테이너가 우측 padding을 4pt로 줄여 텍스트가 한쪽으로 치우친다.
    private var hasAccessories: Bool { showsRevealToggle || showsCopyButton }

    /// 화면에 그릴 문자열. 마스킹 중이면 `•`, 아니면 원문. 클립보드에는 이 값을 쓰지 않는다.
    private var displayedValue: String {
        showsRevealToggle && !isRevealed ? maskedValue : value
    }

    @ViewBuilder
    private var valueContainer: some View {
        if hasAccessories {
            container(displayedValue) { accessoryButtons }
        } else {
            container(displayedValue)
        }
    }

    @ViewBuilder
    private func container<Accessories: View>(
        _ text: String,
        @ViewBuilder accessories: @escaping () -> Accessories
    ) -> some View {
        if isMultiline {
            DVMultilineTextContainer(text, size: size, accessories: accessories)
        } else {
            DVTextContainer(text, size: size, accessories: accessories)
        }
    }

    @ViewBuilder
    private func container(_ text: String) -> some View {
        if isMultiline {
            DVMultilineTextContainer(text, size: size)
        } else {
            DVTextContainer(text, size: size)
        }
    }

    /// 복사·마스킹 토글 버튼. 한 줄/여러 줄 컨테이너 어디에 붙어도 같은 모습이어야 하므로
    /// 컨테이너 선택과 분리해 한 곳에서 만든다.
    @ViewBuilder
    private var accessoryButtons: some View {
        HStack(spacing: 10) {
            if showsCopyButton {
                Button(action: copyValue) {
                    Image(systemName: "doc.on.doc")
                }
            }
            if showsRevealToggle {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                }
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(Color.dv(.gray900))
        .buttonStyle(.plain)
    }

    /// 마스킹 상태와 무관하게 항상 원문 전체를 넣는다.
    private func copyValue() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
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

/// 빈 값이면 두 플래그가 모두 무시되어 액세서리 없는 일반 컨테이너가 된다.
/// 눈·복사 버튼이 하나도 보이지 않아야 하고, 텍스트 좌우 padding이 대칭이어야 한다.
#Preview("Sensitive + Copyable · 빈 값") {
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
