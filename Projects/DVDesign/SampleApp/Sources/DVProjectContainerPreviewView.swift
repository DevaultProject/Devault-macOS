// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct DVProjectContainerPreviewView: View {

    @State private var selectedIndex: Int? = nil

    private let projects: [(String, Int)] = [
        ("CheerLot", 8),
        ("DrinkiG", 8),
        ("LongLongNameExampleProject", 1234),
        ("AnotherProject", 3),
        ("YetAnotherProject", 42),
    ]

    var body: some View {
        HSplitView {
            sidebarColumn
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)
            detailColumn
                .frame(minWidth: 360)
        }
        .frame(minHeight: 480)
        .navigationTitle("DVProjectContainer")
    }
}

// MARK: - Sidebar

extension DVProjectContainerPreviewView {

    private var sidebarColumn: some View {
        List(selection: $selectedIndex) {
            Section("Project") {
                ForEach(projects.indices, id: \.self) { index in
                    DVProjectContainer(
                        name: projects[index].0,
                        count: projects[index].1
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
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .tint(Color.dv(.vaultGreen))
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Detail (placeholder)

extension DVProjectContainerPreviewView {

    private var detailColumn: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                if let index = selectedIndex {
                    Text(projects[index].0)
                        .font(.title2.bold())
                    Text("\(projects[index].1) items")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select a project")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
