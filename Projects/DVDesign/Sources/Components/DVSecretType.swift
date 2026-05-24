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
                    .frame(width: 56, height: 56)
                    .foregroundStyle(Color.dv(.gray600))
            }
        }
    }

    private var typeLabel: some View {
        Text(labelText)
            .dvFont(.headingLG)
            .foregroundStyle(Color.dv(.gray900))
            .multilineTextAlignment(.center)
    }
}
