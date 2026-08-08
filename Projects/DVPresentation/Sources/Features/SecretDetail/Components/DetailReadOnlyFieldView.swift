// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

import DVDesign

/// 조회 모드 전용 읽기 전용 필드 (`DVLabeledField` + `DVTextContainer`).
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
/// read-only 컴포넌트다. `credentialJSON`·`envContent`처럼 값이 긴 필드도 생성 화면이
/// 단일 라인(28pt)으로 처리하므로 조회 화면도 동일하게 맞춘다 — 오버플로우는
/// `DVTextContainer`의 가로 스크롤이 처리한다.
struct DetailReadOnlyFieldView: View {

    let label: String
    let value: String
    /// 기본 마스킹 + 눈 토글. 값 변경이 아니라 표시 전환만 한다.
    var isSensitive: Bool = false
    /// 복사 버튼 노출. 클립보드 쓰기는 이 컴포넌트가 수행한다.
    var isCopyable: Bool = false
    var sizeMode: FormSlotSize = .fullWidth

    @Environment(\.formLayout) private var layout

    /// 마스킹 해제 여부. 로컬 표시 상태이므로 Feature State로 끌어올리지 않는다.
    @State private var isRevealed = false

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    /// `DVTextContainer(secured:isRevealed:size:)`와 동일한 마스킹 규칙.
    private var maskedValue: String {
        String(repeating: "•", count: value.count)
    }

    var body: some View {
        DVLabeledField(label, size: size) {
            valueContainer
        }
    }
}

// MARK: - Subviews

extension DetailReadOnlyFieldView {

    @ViewBuilder
    private var valueContainer: some View {
        switch (isSensitive, isCopyable) {
        case (true, true):
            // 액세서리 2개 조합은 편의 init으로 표현할 수 없어 직접 구성한다(DVTextContainer doc).
            DVTextContainer(isRevealed ? value : maskedValue, size: size) {
                HStack(spacing: 10) {
                    Button(action: copyValue) {
                        Image(systemName: "doc.on.doc")
                    }
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Color.dv(.gray900))
                .buttonStyle(.plain)
            }

        case (true, false):
            DVTextContainer(secured: value, isRevealed: $isRevealed, size: size)

        case (false, true):
            DVTextContainer(copyable: value, size: size, onCopy: copyValue)

        case (false, false):
            DVTextContainer(value, size: size)
        }
    }

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

/// 값이 컨테이너 폭을 넘으면 `DVTextContainer`가 가로 스크롤로 처리한다.
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

#endif
