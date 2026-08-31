// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVStepIndicator: View {

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

extension DVStepIndicator {

    private func dot(isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isActive ? Color.dv(.vaultGreen) : Color.dv(.gray500))
            .frame(width: isActive ? 24 : 8, height: 8)
            .dvAnimation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}
