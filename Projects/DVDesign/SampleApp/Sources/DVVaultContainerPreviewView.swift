// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVVaultContainerPreviewView: View {
    @State private var selectedIndex: Int? = nil

    private let vaults = [
        ("내가 설정한 이름", "2026.04.01"),
        ("이름이름이름",     "2026.04.01"),
        ("Example",         "2026.03.27"),
        ("LongLongNameExam...", "2026.04.01"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive") {
                    VStack(spacing: 4) {
                        ForEach(vaults.indices, id: \.self) { index in
                            DVVaultContainer(
                                name: vaults[index].0,
                                date: vaults[index].1,
                                isSelected: selectedIndex == index
                            ) { selectedIndex = selectedIndex == index ? nil : index }
                        }
                    }
                }

                previewSection("Selected") {
                    DVVaultContainer(name: "내가 설정한 이름", date: "2026.04.01", isSelected: true) {}
                }

                previewSection("Unselected") {
                    DVVaultContainer(name: "내가 설정한 이름", date: "2026.04.01", isSelected: false) {}
                }

                previewSection("Expiring Soon") {
                    DVVaultContainer(
                        name: "내가 설정한 이름",
                        date: "2026.04.01",
                        isSelected: false,
                        trailingIcon: .expiringSoon
                    ) {}
                }
                previewSection("Expired") {
                    DVVaultContainer(
                        name: "내가 설정한 이름",
                        date: "2026.04.01",
                        isSelected: false,
                        trailingIcon: .expired
                    ) {}
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVVaultContainer")
    }
}
