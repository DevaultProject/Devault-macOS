// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVSecretTypePreviewView: View {

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Icon 없음 (기본)") {
                    DVSecretType(labelText: "API Keys / Token")
                }
                previewSection("Icon 있음") {
                    DVSecretType(
                        labelText: "API Keys / Token",
                        icon: Image(systemName: "key.fill")
                    )
                }
                previewSection("다른 타입") {
                    HStack(spacing: 24) {
                        DVSecretType(
                            labelText: "Password",
                            icon: Image(systemName: "lock.fill")
                        )
                        DVSecretType(
                            labelText: "Note",
                            icon: Image(systemName: "note.text")
                        )
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVSecretType")
    }
}
