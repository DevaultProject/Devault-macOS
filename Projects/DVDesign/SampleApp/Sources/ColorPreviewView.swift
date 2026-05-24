// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct ColorPreviewView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                group(title: "Brand", tokens: [
                    (.vaultGreen, "vaultGreen"),
                    (.vaultGreenDark, "vaultGreenDark"),
                    (.vaultGreenTint, "vaultGreenTint"),
                    (.vaultDark, "vaultDark"),
                ])
                group(title: "Gray Scale", tokens: [
                    (.gray900, "gray900"),
                    (.gray800, "gray800"),
                    (.gray700, "gray700"),
                    (.gray600, "gray600"),
                    (.gray500, "gray500"),
                    (.gray400, "gray400"),
                    (.gray300, "gray300"),
                    (.gray200, "gray200"),
                    (.gray100, "gray100"),
                ])
                group(title: "Neutral", tokens: [
                    (.white, "white"),
                    (.black, "black"),
                ])
                group(title: "Semantic", tokens: [
                    (.warning, "warning"),
                    (.danger, "danger"),
                ])
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Color")
    }

    @ViewBuilder
    private func group(title: String, tokens: [(DVColor, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            VStack(spacing: 8) {
                ForEach(tokens, id: \.1) { token, name in
                    row(token: token, name: name)
                }
            }
        }
    }

    private func row(token: DVColor, name: String) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.dv(token))
                .frame(width: 64, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                Text("Color.dv(.\(name))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer()
        }
    }
}
