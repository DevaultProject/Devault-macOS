// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Section("Foundation") {
                    NavigationLink("Typography") {
                        TypographyPreviewView()
                    }
                }

                ForEach(ComponentSection.allCases, id: \.self) { section in
                    Section(section.title) {
                        ForEach(section.components, id: \.self) { component in
                            NavigationLink(component.name) {
                                detailView(for: component)
                            }
                        }
                    }
                }
            }
            .navigationTitle("DVDesign")
        } detail: {
            Text("컴포넌트를 선택하세요")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    @ViewBuilder
    private func detailView(for component: Component) -> some View {
        switch component.name {
        case "DVRadioButton", "DVRadioButtonGroup":
            RadioButtonPreviewView()
        case "DVTextField":
            TextFieldPreviewView()
        case "DVTextContainer":
            TextContainerPreviewView()
        default:
            ComponentPlaceholderView(name: component.name, owner: component.owner)
        }
    }
}

// MARK: - Placeholder Detail

private struct ComponentPlaceholderView: View {
    let name: String
    let owner: String

    var body: some View {
        VStack(spacing: 12) {
            Text(name)
                .font(.title2)
                .fontWeight(.semibold)
            Text("담당: \(owner)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("🚧 구현 예정")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(name)
    }
}

// MARK: - Data

private struct Component: Hashable {
    let name: String
    let owner: String
}

private enum ComponentSection: CaseIterable {
    case yeseong
    case doyeon

    var title: String {
        switch self {
        case .yeseong: return "예성"
        case .doyeon:  return "도연"
        }
    }

    var components: [Component] {
        switch self {
        case .yeseong:
            return [
                Component(name: "DVPageControl", owner: "예성"),
                Component(name: "DVProjectContainer", owner: "예성"),
                Component(name: "DVVaultContainer", owner: "예성"),
                Component(name: "DVCategory", owner: "예성"),
                Component(name: "DVButton", owner: "예성"),
                Component(name: "DVCheckBox", owner: "예성"),
            ]
        case .doyeon:
            return [
                Component(name: "DVRadioButton", owner: "도연"),
                Component(name: "DVRadioButtonGroup", owner: "도연"),
                Component(name: "DVTextContainer", owner: "도연"),
                Component(name: "DVTextField", owner: "도연"),
                Component(name: "DVInputField", owner: "도연"),
                Component(name: "DVDropDown", owner: "도연"),
            ]
        }
    }
}
