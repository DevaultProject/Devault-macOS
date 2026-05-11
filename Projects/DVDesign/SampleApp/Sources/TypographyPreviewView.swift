// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct TypographyPreviewView: View {
    private let sample = "다람쥐 헌 쳇바퀴에 타고파."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                group(title: "Display", tokens: [(.displayBrand, "displayBrand")])
                group(title: "Heading", tokens: [
                    (.headingXL, "headingXL"),
                    (.headingLG, "headingLG"),
                ])
                group(title: "Body", tokens: [
                    (.bodyXL, "bodyXL"),
                    (.bodyLG, "bodyLG"),
                    (.bodyMD, "bodyMD"),
                ])
                group(title: "Caption", tokens: [
                    (.captionLG, "captionLG"),
                    (.captionMDSemibold, "captionMDSemibold"),
                    (.captionMDRegular, "captionMDRegular"),
                ])
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Typography")
    }

    @ViewBuilder
    private func group(title: String, tokens: [(DVFont, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            ForEach(tokens, id: \.1) { token, name in
                row(token: token, name: name)
            }
        }
    }

    private func row(token: DVFont, name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(sample)
                .dvFont(token)
            Text("\(Int(token.size))px / \(Int(token.lineHeightRatio * 100))%")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
