// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Expire Date 필드 (optional).
/// `SecretMetaFields.expireDate`(`Date?`)에 바인딩.
///
/// 날짜 포맷 `yyyy.MM.dd`는 native `.stepperField`가 locale-based라 미보장 —
/// 커스텀 포맷은 D21 followup의 `DVDatePicker`에서 처리 예정.
struct ExpireDateFieldView: View {

    @Binding var expireDate: Date?

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize { mode.pairedFieldSize }

    private var isSet: Bool { expireDate != nil }

    var body: some View {
        DVLabeledField("Expire Date", size: size) {
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
            .frame(width: size.width)
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
            Text("No expired")
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray600))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 28)
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
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isSet)
    }

    /// `DatePicker`가 non-optional `Date`를 요구하므로 옵셔널 shim.
    /// 스텝퍼는 set 상태에서만 렌더되므로 fallback은 방어용.
    var dateBinding: Binding<Date> {
        Binding(
            get: { expireDate ?? Self.defaultInitialDate() },
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
        .environment(\.formLayoutMode, .dual)
        .previewWidth(.wide)
}

#Preview("Set · Dual") {
    ExpireDateFieldPreview(
        initial: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    .padding()
    .environment(\.formLayoutMode, .dual)
    .previewWidth(.wide)
}

#Preview("Set · Single") {
    ExpireDateFieldPreview(
        initial: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    .padding()
    .environment(\.formLayoutMode, .single)
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
