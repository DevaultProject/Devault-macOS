// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVVaultContainerPreviewView: View {
    @State private var selectedIndex: Int? = nil

    private let vaults: [(String, String, DVVaultContainer.TrailingIcon?)] = [
        ("내가 설정한 이름",       "2026.04.01", nil),
        ("이름이름이름",           "2026.04.01", nil),
        ("Example",               "2026.03.27", nil),
        ("LongLongNameExample",   "2026.04.01", nil),
        ("만료 임박 항목",          "2026.04.01", .expiringSoon),
        ("이름이름이름",           "2026.04.01", .expiringSoon),
        ("만료된 항목",            "2026.03.27", .expired),
        ("LongLongNameExample",   "2025.04.01", .expired),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection("Interactive (List)") {
                    List(selection: $selectedIndex) {
                        ForEach(vaults.indices, id: \.self) { index in
                            DVVaultContainer(
                                name: vaults[index].0,
                                date: vaults[index].1,
                                trailingIcon: vaults[index].2
                            )
                            .tag(index)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .contextMenu {
                                Button("이름 변경") {}
                                Divider()
                                Button("삭제", role: .destructive) {}
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .tint(Color.dv(.vaultGreen))
                    .frame(width: 280, height: 260)
                }

                previewSection("Default") {
                    DVVaultContainer(name: "내가 설정한 이름", date: "2026.04.01")
                        .frame(width: 280)
                }

                previewSection("Expiring Soon") {
                    DVVaultContainer(
                        name: "내가 설정한 이름",
                        date: "2026.04.01",
                        trailingIcon: .expiringSoon
                    )
                    .frame(width: 280)
                }

                previewSection("Expired") {
                    DVVaultContainer(
                        name: "내가 설정한 이름",
                        date: "2026.04.01",
                        trailingIcon: .expired
                    )
                    .frame(width: 280)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("DVVaultContainer")
    }
}
