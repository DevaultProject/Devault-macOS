// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVSecretType: View {

    // MARK: - Properties

    public let labelText: String
    public let icon: Image?

    // MARK: - Init

    public init(
        labelText: String,
        icon: Image? = nil
    ) {
        self.labelText = labelText
        self.icon = icon
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 16) {
            iconCircle
            typeLabel
        }
    }
}

// MARK: - Subviews

extension DVSecretType {

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(Color.dv(.gray200))
                .frame(width: 162, height: 162)

            if let icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color.dv(.gray600))
            }
        }
    }

    /// 그리드 열이 좁아져도 라벨이 줄바꿈되지 않도록 고정한다.
    /// 줄바꿈을 허용하면 행 높이가 커지면서 그리드 전체 높이가 연쇄적으로 늘어난다.
    private var typeLabel: some View {
        Text(labelText)
            .dvFont(.headingLG)
            .foregroundStyle(Color.dv(.gray900))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}
