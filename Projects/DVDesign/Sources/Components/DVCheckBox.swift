// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 체크 상태를 표시하고 토글을 호출자에게 위임하는 체크박스.
///
/// ## 읽기 전용 모드
///
/// 체크 상태를 **표시만** 하고 값 변경을 허용하지 않아야 하는 화면(예: 시크릿 조회)에서는
/// ``init(readOnly:)``를 사용합니다. 이 모드에서는 `Button`과 호버 핸들러가 **뷰 트리에
/// 아예 부착되지 않으며**, 따라서 접근성 트레이트도 `.isButton`을 갖지 않습니다.
///
/// `.disabled(true)`와 다른 점: `.disabled`는 컨트롤을 "비활성" 외관으로 바꾸지만
/// 여기서는 **체크 상태의 색 표현을 그대로 유지**한 채 인터랙션만 제거합니다 —
/// 조회 화면에서 켜져 있는 값이 흐리게 보이면 안 되기 때문입니다.
/// ``DVRadioButton``의 `isInteractive`와 같은 규칙입니다.
public struct DVCheckBox: View {

    // MARK: - Properties

    public let isChecked: Bool
    public let isInteractive: Bool
    public let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    /// - Parameters:
    ///   - isChecked: 현재 체크 여부. 색과 체크마크 표시를 결정하며, 호출자가 원천 값을 소유합니다.
    ///   - isInteractive: `false`면 클릭·호버 핸들러를 부착하지 않아 값 변경이 불가능해집니다. 기본 `true`.
    ///   - action: 클릭 시 호출됩니다. `isInteractive == false`면 호출되지 않습니다.
    public init(
        isChecked: Bool,
        isInteractive: Bool = true,
        action: @escaping () -> Void
    ) {
        self.isChecked = isChecked
        self.isInteractive = isInteractive
        self.action = action
    }

    /// 상태 표시만 하는 읽기 전용 체크박스를 생성합니다.
    ///
    /// ```swift
    /// DVCheckBox(readOnly: true)
    /// ```
    public init(readOnly isChecked: Bool) {
        self.init(isChecked: isChecked, isInteractive: false, action: {})
    }

    // MARK: - Body

    public var body: some View {
        if isInteractive {
            Button(action: action) {
                checkboxShape
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .accessibilityAddTraits(isChecked ? .isSelected : [])
        } else {
            checkboxShape
        }
    }
}

// MARK: - Subviews

extension DVCheckBox {

    private var checkboxShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.5)
                .fill(isChecked ? Color.dv(.vaultGreen) : Color.dv(.gray300))
                .frame(width: 16, height: 16)
                .overlay(borderOverlay)

            if isChecked {
                checkmarkIcon
            }
        }
    }

    private var checkmarkIcon: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.dv(.white))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 5.5)
            .stroke(
                isHovered && !isChecked ? Color.dv(.gray400) : Color.clear,
                lineWidth: 1
            )
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Interactive") {
    DVCheckBoxPreview()
        .padding()
}

/// 읽기 전용도 체크 상태의 색을 그대로 유지한다 — 흐려지면 안 된다.
#Preview("ReadOnly") {
    HStack(spacing: 12) {
        DVCheckBox(readOnly: true)
        DVCheckBox(readOnly: false)
    }
    .padding()
}

private struct DVCheckBoxPreview: View {
    @State private var isChecked = false

    var body: some View {
        DVCheckBox(isChecked: isChecked) { isChecked.toggle() }
    }
}

#endif
