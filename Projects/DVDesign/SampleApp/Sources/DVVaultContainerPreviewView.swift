// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVVaultContainerPreviewView: View {

    @State private var selectedIndex: Int? = nil

    private let vaults: [(String, String, DVVaultContainer.TrailingIcon?, String?)] = [
        ("내가 설정한 이름",         "2026.04.01", nil, nil),
        ("이름이름이름",            "2026.04.01", nil, nil),
        ("Example",                "2026.03.27", nil, nil),
        ("LongLongNameExampleVault","2026.04.01", nil, nil),
        ("Google 계정",             "2026.04.01", nil, "google"),
        ("GitHub 계정",             "2026.04.01", nil, "github"),
        ("네이버 계정",              "2026.04.01", nil, "naver"),
        ("카카오톡 계정",             "2026.04.01", nil, "kakaotalk"),
        ("만료 임박 항목",            "2026.04.01", .expiringSoon, "google"),
        ("이름이름이름",            "2026.04.01", .expiringSoon, nil),
        ("만료된 항목",              "2026.03.27", .expired, "github"),
        ("LongLongNameExampleVault","2025.04.01", .expired, nil),
    ]

    var body: some View {
        HSplitView {
            vaultListColumn
                .frame(minWidth: 260, idealWidth: 320, maxWidth: 420)
            detailColumn
                .frame(minWidth: 360)
        }
        .frame(minHeight: 480)
        .navigationTitle("DVVaultContainer")
    }
}

// MARK: - Columns

extension DVVaultContainerPreviewView {

    private var vaultListColumn: some View {
        VStack(spacing: 0) {
            listHeader
            vaultList
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var listHeader: some View {
        HStack {
            Text("Star")
                .font(.title2.bold())
            Spacer()
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var vaultList: some View {
        List(selection: $selectedIndex) {
            ForEach(vaults.indices, id: \.self) { index in
                DVVaultContainer(
                    name: vaults[index].0,
                    date: vaults[index].1,
                    service: vaults[index].3,
                    trailingIcon: vaults[index].2,
                    isSelected: selectedIndex == index
                )
                .tag(index)
                .contextMenu {
                    Button("이름 변경") {}
                    Button("복제")     {}
                    Divider()
                    Button("삭제", role: .destructive) {}
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .tint(Color.dv(.vaultGreen))
    }

    private var detailColumn: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                if let index = selectedIndex {
                    Text(vaults[index].0)
                        .font(.title2.bold())
                    Text(vaults[index].1)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select a vault")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
