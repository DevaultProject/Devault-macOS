// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct SizePreviewView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Size")
    }

    private var section: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DVComponentSize")
                .font(.title2)
                .fontWeight(.bold)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(DVComponentSize.allCases, id: \.self) { size in
                    row(size: size)
                }
            }
        }
    }

    private func row(size: DVComponentSize) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label(for: size))
                    .font(.body)
                    .frame(width: 40, alignment: .leading)
                Text("\(Int(size.width))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.dv(.vaultGreenTint))
                .frame(width: size.width, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.dv(.vaultGreen), lineWidth: 1)
                )
        }
    }

    private func label(for size: DVComponentSize) -> String {
        switch size {
        case .xs: return "xs"
        case .sm: return "sm"
        case .md: return "md"
        case .lg: return "lg"
        }
    }
}
