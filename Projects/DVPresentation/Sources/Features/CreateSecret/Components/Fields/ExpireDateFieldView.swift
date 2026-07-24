// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// CreateSecret 폼의 Expire Date 필드 (optional).
/// `SecretMetaFields.expireDate`(`Date?`)에 바인딩. 기본값은 nil("No expire")이며,
/// 체크박스로 "만료 설정"을 활성화하면 `defaultInitialDate`(오늘+30일)로 초기화되고 DatePicker가 노출된다.
///
/// 임시로 SwiftUI `DatePicker(.stepperField)` 사용 — macOS native 트리거.
/// DV 브랜드 색상만 `.tint`로 통일. 디자인 완성도가 필요해지면 별도 이슈에서 `DVCalendarPicker` 개발 후 교체.
struct ExpireDateFieldView: View {

    @Binding var expireDate: Date?

    @Environment(\.formLayoutMode) private var mode

    private var size: DVComponentSize { mode.pairedFieldSize }

    /// `expireDate != nil`이 checked 상태의 유일한 진실 — 별도 로컬 State를 두면 바인딩 소스와 어긋남.
    private var isChecked: Bool { expireDate != nil }

    /// `DatePicker`가 non-optional `Date`를 요구하므로 옵셔널 shim.
    /// checked 상태에서만 렌더되기 때문에 get의 폴백은 방어용.
    private var dateBinding: Binding<Date> {
        Binding(
            get: { expireDate ?? Self.defaultInitialDate() },
            set: { expireDate = $0 }
        )
    }

    /// 체크박스를 처음 켰을 때 세팅되는 기본 만료일. 대부분의 secret에 관용적인 30일.
    private static func defaultInitialDate() -> Date {
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }

    var body: some View {
        DVLabeledField("Expire Date", size: size) {
            HStack(spacing: 8) {
                DVCheckBox(isChecked: isChecked) {
                    expireDate = isChecked ? nil : Self.defaultInitialDate()
                }

                if isChecked {
                    DatePicker(
                        "",
                        selection: dateBinding,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.stepperField)
                    .labelsHidden()
                    .tint(Color.dv(.vaultGreen))
                } else {
                    Text("No expire")
                        .dvFont(.bodyMD)
                        .foregroundStyle(Color.dv(.gray500))
                }
            }
            .frame(width: size.width, alignment: .leading)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("No expire (default) · Dual") {
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
