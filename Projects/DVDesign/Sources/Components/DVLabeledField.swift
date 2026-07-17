// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템의 폼 필드 래퍼.
///
/// `DVLabeledField`는 폼 안에서 반복되는 "Label + (*) 필수 표시 + 입력 슬롯 + 우측 힌트"
/// 3파트 조합을 하나의 컴포넌트로 묶은 wrapper입니다. Figma의 Field 컴포넌트
/// (node 467:16059)에 대응합니다.
///
/// 실제 입력 컨트롤은 caller가 `@ViewBuilder` content로 자유롭게 지정 —
/// ``DVTextField``, ``DVDropdown``, ``DVMultilineTextField``, ``DVChipsField``
/// 등 어떤 뷰든 넣을 수 있습니다.
///
/// ## 시각 스펙
///
/// - Label 로우와 입력 슬롯 사이 vertical spacing: 10pt
/// - Label: ``DVFont/bodyMD`` (13pt medium), ``DVColor/gray700``
/// - 필수 표시 `(*)`: ``DVColor/warning`` (Figma `#c83535`)
/// - Trailing hint: 라벨 로우 우측 정렬, 1줄 tail truncation
///   - ``TrailingHint/detected(_:)``: ``DVColor/vaultGreen`` — 감지 엔진이 서비스 인식했을 때
///   - ``TrailingHint/warning(_:)``: ``DVColor/warning`` — validation 실패 메시지
///
/// ## 사이즈
///
/// 컴포넌트 너비는 ``DVComponentSize`` 를 따르며, 내부 입력 뷰의 너비와
/// 일치시켜야 라벨 로우가 정렬됩니다.
///
/// ## 사용
///
/// ```swift
/// // 감지 엔진 결과 표시
/// DVLabeledField("Name", isRequired: true, trailingHint: .detected("GitHub"), size: .lg) {
///     DVTextField("e.g DeVault", text: $name, size: .lg)
/// }
///
/// // Validation 실패 메시지
/// DVLabeledField("Value", isRequired: true, trailingHint: .warning("필수 항목입니다"), size: .lg) {
///     DVTextField("value", text: $value, size: .lg)
/// }
///
/// // 힌트 없음
/// DVLabeledField("Memo", size: .lg) {
///     DVTextField("optional", text: $memo, size: .lg)
/// }
/// ```
public struct DVLabeledField<Content: View>: View {

    // MARK: - Types

    /// 라벨 로우 우측에 표시되는 힌트.
    public enum TrailingHint: Equatable {
        /// 자동 감지 결과 표시 (초록). 예: `"Auto-detected: GitHub"`
        case detected(String)

        /// Validation 실패 등 경고 (빨강). 예: `"필수 항목입니다"`
        case warning(String)
    }

    // MARK: - Properties

    private let label: String
    private let isRequired: Bool
    private let trailingHint: TrailingHint?
    private let size: DVComponentSize
    private let content: () -> Content

    // MARK: - Init

    /// 라벨 래퍼를 생성합니다.
    ///
    /// - Parameters:
    ///   - label: 표시할 라벨 문자열 (예: "Name").
    ///   - isRequired: 라벨 뒤에 `(*)` 필수 표시를 붙일지 여부. 기본 `false`.
    ///   - trailingHint: 라벨 로우 우측에 표시할 힌트. 기본 `nil`.
    ///   - size: 너비 변형. 내부 입력 뷰와 동일 사이즈로 넘겨야 정렬이 맞습니다.
    ///     기본값 ``DVComponentSize/md``.
    ///   - content: 라벨 아래 배치할 입력 컨트롤.
    public init(
        _ label: String,
        isRequired: Bool = false,
        trailingHint: TrailingHint? = nil,
        size: DVComponentSize = .md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.trailingHint = trailingHint
        self.size = size
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            labelRow
            content()
        }
        .frame(width: size.width, alignment: .leading)
    }
}

// MARK: - Subviews

extension DVLabeledField {

    private var labelRow: some View {
        HStack(spacing: 0) {
            Text(label)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray700))
            if isRequired {
                Text("(*)")
                    .dvFont(.bodyMD)
                    .foregroundStyle(Color.dv(.required))
            }
            Spacer(minLength: 8)
            hintView
        }
    }

    @ViewBuilder
    private var hintView: some View {
        switch trailingHint {
        case .none:
            EmptyView()
        case .detected(let text):
            Text(text)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.vaultGreen))
                .lineLimit(1)
                .truncationMode(.tail)
        case .warning(let text):
            Text(text)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.required))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

// MARK: - Previews

#Preview("Basic (no hint)") {
    DVLabeledFieldBasicPreview()
        .padding()
}

#Preview("Detected hint") {
    DVLabeledFieldDetectedPreview()
        .padding()
}

#Preview("Warning hint") {
    DVLabeledFieldWarningPreview()
        .padding()
}

#Preview("Sizes") {
    DVLabeledFieldSizesPreview()
        .padding()
}

private struct DVLabeledFieldBasicPreview: View {
    @State private var text = ""
    var body: some View {
        DVLabeledField("Memo", size: .lg) {
            DVTextField("optional", text: $text, size: .lg)
        }
    }
}

private struct DVLabeledFieldDetectedPreview: View {
    @State private var text = "ghp_xxxxxxxx"
    var body: some View {
        DVLabeledField(
            "Value",
            isRequired: true,
            trailingHint: .detected("Auto-detected: GitHub"),
            size: .lg
        ) {
            DVTextField("secret value", text: $text, size: .lg)
        }
    }
}

private struct DVLabeledFieldWarningPreview: View {
    @State private var text = ""
    var body: some View {
        DVLabeledField(
            "Name",
            isRequired: true,
            trailingHint: .warning("필수 항목입니다"),
            size: .lg
        ) {
            DVTextField("e.g DeVault", text: $text, size: .lg)
        }
    }
}

private struct DVLabeledFieldSizesPreview: View {
    @State private var xs = ""
    @State private var sm = ""
    @State private var md = ""
    @State private var lg = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DVLabeledField("XS", isRequired: true, size: .xs) {
                DVTextField("XS", text: $xs, size: .xs)
            }
            DVLabeledField("SM", isRequired: true, size: .sm) {
                DVTextField("SM", text: $sm, size: .sm)
            }
            DVLabeledField("MD", isRequired: true, trailingHint: .detected("hint"), size: .md) {
                DVTextField("MD", text: $md, size: .md)
            }
            DVLabeledField("LG", isRequired: true, trailingHint: .detected("Auto-detected: GitHub"), size: .lg) {
                DVTextField("LG", text: $lg, size: .lg)
            }
        }
    }
}
