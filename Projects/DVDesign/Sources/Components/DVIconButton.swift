// Copyright © 2026 Devault. All rights reserved

import SwiftUI

// MARK: - DVIconButton

/// 라벨 없이 아이콘만 있는 작은 버튼. hover·press 되먹임을 준다.
///
/// **색은 호출부가 정한다.** 회색 아이콘은 회색 계열에서, 초록 아이콘은 초록 계열에서
/// 움직여야 버튼의 성격이 유지된다.
public struct DVIconButton: View {

    // MARK: - Properties

    private let systemName: String
    private let font: DVFont
    private let idle: DVColor
    private let hovered: DVColor
    private let pressed: DVColor
    /// 색 토큰만으로 press와 hover가 구분되지 않을 때 쓰는 보조 수단.
    private let pressedOpacity: Double
    private let hitSize: CGFloat
    private let action: () -> Void

    @State private var isHovered = false

    // MARK: - Init

    public init(
        systemName: String,
        font: DVFont = .captionLG,
        idle: DVColor,
        hovered: DVColor,
        pressed: DVColor,
        pressedOpacity: Double = 1,
        hitSize: CGFloat = 22,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.font = font
        self.idle = idle
        self.hovered = hovered
        self.pressed = pressed
        self.pressedOpacity = pressedOpacity
        self.hitSize = hitSize
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
                isHovered: isHovered,
                idle: idle,
                hovered: hovered,
                pressed: pressed,
                pressedOpacity: pressedOpacity,
                hitSize: hitSize
            )
        )
        .onHover { isHovered = $0 }
        .animation(MotionMetrics.hover, value: isHovered)
    }
}

// MARK: - ButtonStyle

private struct DVIconButtonStyle: ButtonStyle {

    let isHovered: Bool
    let idle: DVColor
    let hovered: DVColor
    let pressed: DVColor
    let pressedOpacity: Double
    let hitSize: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.dv(tint(isPressed: configuration.isPressed)))
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            // 배경이 없으면 넓힌 영역이 클릭을 받지 못한다.
            .frame(width: hitSize, height: hitSize)
            .contentShape(Rectangle())
            .animation(MotionMetrics.hover, value: configuration.isPressed)
    }

    private func tint(isPressed: Bool) -> DVColor {
        if isPressed { return pressed }
        return isHovered ? hovered : idle
    }
}
