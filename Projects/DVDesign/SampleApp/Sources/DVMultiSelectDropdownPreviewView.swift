// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

/// `DVMultiSelectDropdown`의 **연속 선택** 회귀 화면.
///
/// 여러 항목을 잇따라 누를 때 팝오버의 체크 상태가 매번 따라오는지 본다. 한때 방금 누른 행만
/// 갱신되고 이전에 누른 행들은 옛 상태로 남았고, 몇 번은 멀쩡해서 눈으로는 판정이 어려웠다.
///
/// TCA도 Array↔Set 어댑터도 없이 순수 `@State`만 쓰므로, 여기서 어긋나면 원인은 컴포넌트 안에 있다.
/// 나머지 설정은 `ProjectFieldView`와 맞춘다 — `groupsSelectedAtTop: true`, 검색 없음, add-new 있음.
struct DVMultiSelectDropdownPreviewView: View {

    private struct Item: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }

    private let items: [Item] = [
        .init(name: "DeVault"),
        .init(name: "DrinkiG"),
        .init(name: "CheerLot"),
        .init(name: "SipStream"),
        .init(name: "Example"),
    ]

    @State private var selection: Set<UUID> = []
    @State private var log: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                DVMultiSelectDropdown(
                    "Select Project",
                    items: items,
                    selection: $selection,
                    label: \.name,
                    size: .md,
                    onCreate: { log.insert("+ Add new 눌림", at: 0) },
                    createLabel: "Add new project",
                    emptyMessage: "No projects yet",
                    groupsSelectedAtTop: true
                )

                stateReadout
                Spacer(minLength: 0)
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            // 열기 전에 두 개를 선택해 둬야 Selected / All 두 섹션이 모두 생긴다.
            if selection.isEmpty {
                selection = Set(items.prefix(2).map(\.id))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("연속 선택 재현")
                .font(.title2).fontWeight(.semibold)
            Text("팝오버를 열고 여러 항목을 **연속으로** 눌러보세요. 아래 상태가 누를 때마다 즉시 "
                 + "따라오면 컴포넌트는 정상입니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    /// 팝오버 밖에서 본 실제 상태. 팝오버 안 체크와 여기가 어긋나면 **렌더 문제**,
    /// 둘 다 틀리면 **쓰기 유실**이다.
    private var stateReadout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("selection (\(selection.count)개)")
                .font(.headline)
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Image(systemName: selection.contains(item.id) ? "checkmark.square.fill" : "square")
                        .foregroundStyle(selection.contains(item.id) ? .green : .secondary)
                    Text(item.name)
                }
                .font(.system(.body, design: .monospaced))
            }
            if !log.isEmpty {
                Divider()
                ForEach(log, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
    }
}
