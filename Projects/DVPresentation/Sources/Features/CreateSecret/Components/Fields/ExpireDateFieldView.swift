// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Expire Date 필드 (optional).
/// `SecretMetaFields.expireDate`(`Date?`)에 바인딩.
///
/// 임시로 SwiftUI `DatePicker(.compact)` 사용 — macOS native 트리거 + 시스템 팝오버.
/// DV 브랜드 색상만 `.tint`로 통일. 디자인 완성도가 필요해지면 별도 이슈에서 `DVCalendarPicker` 개발 후 교체.
struct ExpireDateFieldView: View {

    @Binding var expireDate: Date?

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize { mode.pairedFieldSize }

    /// `DatePicker`가 non-optional `Date`를 요구하므로 optional 바인딩 shim.
    /// get: `nil`이면 오늘 표시. set: 사용자 선택을 그대로 반영.
    private var dateBinding: Binding<Date> {
        Binding(
            get: { expireDate ?? Date() },
            set: { expireDate = $0 }
        )
    }

    var body: some View {
        DVLabeledField("Expire Date", size: size) {
            DatePicker(
                "",
                selection: dateBinding,
                displayedComponents: [.date]
            )
            .datePickerStyle(.stepperField)
            .labelsHidden()
            .tint(Color.dv(.vaultGreen))
            .frame(width: size.width, alignment: .leading)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Not set · Dual") {
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
