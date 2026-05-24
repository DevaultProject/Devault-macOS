// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVPageControl: View {

    // MARK: - Properties

    public let totalSteps: Int
    public let currentStep: Int

    // MARK: - Init

    public init(totalSteps: Int, currentStep: Int) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalSteps, id: \.self) { step in
                dot(isActive: step == currentStep)
            }
        }
    }
}

// MARK: - Subviews

extension DVPageControl {

    private func dot(isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isActive ? Color.dv(.vaultGreen) : Color.dv(.gray300))
            .frame(width: isActive ? 24 : 8, height: 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}
