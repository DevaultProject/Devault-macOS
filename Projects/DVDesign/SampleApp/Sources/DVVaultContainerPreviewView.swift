// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVVaultContainerPreviewView: View {

    @State private var selectedIndex: Int? = nil

    /// `typeIcon`은 DVDesign이 알 필요 없는 실제 secretType과 무관한 값이라, 폴백 렌더링 확인용으로 하나만 재사용한다.
    private let placeholderTypeIcon = Image(systemName: "key.fill")

    private let vaults: [(String, String, DVVaultContainer.TrailingIcon?, String?, Bool)] = [
        ("내가 설정한 이름",         "2026.04.01", nil, nil, true),
        ("이름이름이름",            "2026.04.01", nil, nil, true),
        ("Example",                "2026.03.27", nil, nil, true),
        ("LongLongNameExampleVault","2026.04.01", nil, nil, true),
        ("Google 계정",             "2026.04.01", nil, "google", false),
        ("GitHub 계정",             "2026.04.01", nil, "github", false),
        ("네이버 계정",              "2026.04.01", nil, "naver", false),
        ("카카오톡 계정",             "2026.04.01", nil, "kakaotalk", false),
        ("만료 임박 항목",            "2026.04.01", .expiringSoon, "google", false),
        ("이름이름이름",            "2026.04.01", .expiringSoon, nil, true),
        ("만료된 항목",              "2026.03.27", .expired, "github", false),
        ("LongLongNameExampleVault","2025.04.01", .expired, nil, true),
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
                    typeIcon: vaults[index].4 ? placeholderTypeIcon : nil,
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
