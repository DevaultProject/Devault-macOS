// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 라벨 로우 우측에 표시되는 힌트.
///
/// `Content`와 무관한 값이라 ``DVLabeledField`` 밖에 둔다. 제네릭 안에 중첩하면
/// `DVLabeledField<A>.TrailingHint`와 `DVLabeledField<B>.TrailingHint`가 다른 타입이 되어,
/// 같은 힌트를 서로 다른 content(단일 줄 ↔ 여러 줄)에 넘길 수 없다.
public enum DVFieldTrailingHint: Equatable {
    /// 자동 감지 결과 표시 (초록). 예: `"Auto-detected: GitHub"`
    case detected(String)

    /// Validation 실패 등 경고 (빨강). 예: `"필수 항목입니다"`
    case warning(String)
}

/// 폼 필드 래퍼 — Label + `(*)` 필수 표시 + 입력 슬롯 + 우측 hint.
///
/// 입력 컨트롤은 caller가 `@ViewBuilder`로 자유롭게 지정. 우측 hint는
/// 감지 결과(초록, ``TrailingHint/detected(_:)``) 또는 validation 경고(빨강,
/// ``TrailingHint/warning(_:)``)를 표시합니다.
///
/// 내부 입력 뷰와 ``DVComponentSize``를 일치시켜야 라벨 로우가 정렬됩니다.
///
/// > TODO(size-env): 현재는 caller가 wrapper와 내부 input에 동일한 `size`를
/// > 각각 전달해야 함. 향후 `EnvironmentValues.dvComponentSize`를 도입해
/// > wrapper가 자식에게 자동 전파하는 방식으로 개선 여지 있음.
public struct DVLabeledField<Content: View>: View {

    // MARK: - Types

    /// ``DVFieldTrailingHint``의 별칭. 기존 `DVLabeledField<_>.TrailingHint` 표기를 유지한다.
    public typealias TrailingHint = DVFieldTrailingHint

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
        .dvComponentWidth(size, alignment: .leading)
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

#if DEBUG

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

#endif
