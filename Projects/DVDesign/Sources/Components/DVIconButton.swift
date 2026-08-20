// Copyright © 2026 Devault. All rights reserved

import SwiftUI

// MARK: - DVIconButton

/// 라벨 없이 아이콘만 있는 작은 버튼. hover·press·disabled 되먹임을 준다.
///
/// **색은 호출부가 정한다.** 회색 아이콘은 회색 계열에서, 초록 아이콘은 초록 계열에서
/// 움직여야 버튼의 성격이 유지된다. 비활성 외형까지 이 타입이 갖는 것은, 호출부가 따로
/// 계산하면 비활성 사유가 늘 때 외형만 활성으로 남기 때문이다.
public struct DVIconButton: View {

    // MARK: - Properties

    private let systemName: String
    private let font: DVFont
    private let idle: DVColor
    private let hovered: DVColor
    private let pressed: DVColor
    /// 비활성일 때의 색. `nil`이면 `idle`을 흐리게 처리한다 —
    /// 유채색 아이콘은 흐리게만 하면 "연한 초록"이 되어 꺼진 것으로 읽히지 않는다.
    private let disabled: DVColor?
    /// 색 토큰만으로 press와 hover가 구분되지 않을 때 쓰는 보조 수단.
    private let pressedOpacity: Double
    private let hitSize: CGFloat
    /// 높이를 폭과 다르게 잡아야 할 때만 준다. `nil`이면 `hitSize`로 정사각.
    private let hitHeight: CGFloat?
    private let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    public init(
        systemName: String,
        font: DVFont = .captionLG,
        idle: DVColor,
        hovered: DVColor,
        pressed: DVColor,
        disabled: DVColor? = nil,
        pressedOpacity: Double = 1,
        hitSize: CGFloat = 22,
        hitHeight: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.font = font
        self.idle = idle
        self.hovered = hovered
        self.pressed = pressed
        self.disabled = disabled
        self.pressedOpacity = pressedOpacity
        self.hitSize = hitSize
        self.hitHeight = hitHeight
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .dvFont(font)
        }
        .buttonStyle(
            DVIconButtonStyle(
                isEnabled: isEnabled,
                isHovered: isHovered,
                idle: idle,
                hovered: hovered,
                pressed: pressed,
                disabled: disabled,
                pressedOpacity: pressedOpacity,
                hitSize: hitSize,
                hitHeight: hitHeight ?? hitSize
            )
        )
        .onHover { isHovered = $0 }
        // 틴트가 두 값에 의존하므로 둘 다 관찰한다.
        .animation(MotionMetrics.hover, value: isHovered)
        .animation(MotionMetrics.hover, value: isEnabled)
    }
}

// MARK: - ButtonStyle

private struct DVIconButtonStyle: ButtonStyle {

    /// 비활성 색 토큰을 받지 못했을 때 대신 낮추는 불투명도.
    private static let disabledOpacity: Double = 0.4

    let isEnabled: Bool
    let isHovered: Bool
    let idle: DVColor
    let hovered: DVColor
    let pressed: DVColor
    let disabled: DVColor?
    let pressedOpacity: Double
    let hitSize: CGFloat
    let hitHeight: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.dv(tint(isPressed: configuration.isPressed)))
            .opacity(opacity(isPressed: configuration.isPressed))
            // 배경이 없으면 넓힌 영역이 클릭을 받지 못한다.
            .frame(width: hitSize, height: hitHeight)
            .contentShape(Rectangle())
            .animation(MotionMetrics.hover, value: configuration.isPressed)
    }

    /// 호버 색은 누를 수 있다는 신호라 비활성일 때는 주지 않는다.
    private func tint(isPressed: Bool) -> DVColor {
        guard isEnabled else { return disabled ?? idle }
        if isPressed { return pressed }
        return isHovered ? hovered : idle
    }

    private func opacity(isPressed: Bool) -> Double {
        guard isEnabled else { return disabled == nil ? Self.disabledOpacity : 1 }
        return isPressed ? pressedOpacity : 1
    }
}
