// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Expire Date 필드 (optional).
/// `SecretMetaFields.expireDate`(`Date?`)에 바인딩. 날짜 포맷은 native `.stepperField` locale 기준.
struct ExpireDateFieldView: View {

    @Binding var expireDate: Date?

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize { layout.size(for: .paired) }

    private var isSet: Bool { expireDate != nil }

    var body: some View {
        DVLabeledField(.module("Expire Date"), size: size) {
            HStack(spacing: 6) {
                Group {
                    if isSet {
                        stepperPicker
                    } else {
                        activateButton
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trashButton
            }
            // `.frame(width: size.width)`를 직접 쓰면 `.fill` 정책에서 래퍼만 늘어나고
            // 내부 컨트롤은 토큰 폭에 남아 어긋난다. DVDesign의 폭 정책 modifier를 따른다.
            .dvComponentWidth(size)
        }
    }
}

// MARK: - Subviews

private extension ExpireDateFieldView {

    /// nil 상태의 "No expired" 트리거. gray300 textContainer 배경 —
    /// 다른 dropdown 트리거(DVDropdown/ProjectFieldView)와 시각 일관성.
    /// 클릭 시 기본값 세팅 → 스텝퍼 UI로 전환.
    var activateButton: some View {
        Button {
            expireDate = Self.defaultInitialDate()
        } label: {
            Text(.module("No expiration"))
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray600))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: DVComponentSize.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dv(.gray300))
                )
        }
        .buttonStyle(.plain)
    }

    var stepperPicker: some View {
        DatePicker(
            "",
            selection: dateBinding,
            displayedComponents: [.date]
        )
        .datePickerStyle(.stepperField)
    }

    var trashButton: some View {
        Button {
            expireDate = nil
        } label: {
            Image(systemName: "trash")
                .font(DVFont.bodyLG.font)
                .foregroundStyle(isSet ? Color.dv(.gray700) : Color.dv(.gray400))
                .frame(width: DVComponentSize.fieldHeight, height: DVComponentSize.fieldHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isSet)
    }

    /// `DatePicker`가 non-optional `Date`를 요구하므로 옵셔널 shim.
    /// 스텝퍼는 `isSet == true`일 때만 렌더되므로 fallback(`Date()`)은 실행 안 되는 방어용 —
    /// `defaultInitialDate()`를 재계산할 필요 없어 trivial expression으로 대체.
    var dateBinding: Binding<Date> {
        Binding(
            get: { expireDate ?? Date() },
            set: { expireDate = $0 }
        )
    }

    /// nil → set 첫 전이 시 세팅되는 기본 만료일. 대부분의 secret에 관용적인 30일.
    static func defaultInitialDate() -> Date {
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
}

// MARK: - Preview

#if DEBUG

#Preview("No expired (nil) · Dual") {
    ExpireDateFieldPreview()
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Set · Dual") {
    ExpireDateFieldPreview(
        initial: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

#Preview("Set · Single") {
    ExpireDateFieldPreview(
        initial: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    .padding()
    .formLayout(.single)
    .previewWidth(.narrow)
}

private struct ExpireDateFieldPreview: View {
    @State private var expireDate: Date?

    init(initial: Date? = nil) {
        _expireDate = State(initialValue: initial)
    }

    var body: some View {
        ExpireDateFieldView(expireDate: $expireDate)
    }
}

#endif
