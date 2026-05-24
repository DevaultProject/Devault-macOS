// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVStepIndicatorPreviewView: View {

    // MARK: - Properties

    @State private var currentStep = 0

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive (탭해서 이동)") {
                    VStack(spacing: 16) {
                        DVStepIndicator(totalSteps: 3, currentStep: currentStep)
                        HStack(spacing: 8) {
                            DVButton(titleText: "이전", style: .secondary) {
                                if currentStep > 0 { currentStep -= 1 }
                            }
                            .frame(width: 80)
                            .disabled(currentStep == 0)

                            DVButton(titleText: "다음", style: .secondary) {
                                if currentStep < 2 { currentStep += 1 }
                            }
                            .frame(width: 80)
                            .disabled(currentStep == 2)
                        }
                    }
                }
                previewSection("Step 1 / 3") {
                    DVStepIndicator(totalSteps: 3, currentStep: 0)
                }
                previewSection("Step 2 / 3") {
                    DVStepIndicator(totalSteps: 3, currentStep: 1)
                }
                previewSection("Step 3 / 3") {
                    DVStepIndicator(totalSteps: 3, currentStep: 2)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVStepIndicator")
    }
}
