// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign

// MARK: - SelectSecretTypeView

struct SelectSecretTypeView: View {

    // MARK: - Properties

    let store: StoreOf<SelectSecretTypeFeature>

    // MARK: - Body

    var body: some View {
        typeGrid
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Subviews

extension SelectSecretTypeView {

    private var typeGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 40), count: 3),
            spacing: 40
        ) {
            ForEach(CreatableSecretType.allCases, id: \.self) { type in
                typeCard(type)
            }
        }
    }

    private func typeCard(_ type: CreatableSecretType) -> some View {
        Button {
            store.send(.didSelectType(type))
        } label: {
            DVSecretType(
                labelText: String(localized: type.displayName),
                icon: type.icon
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Grid") {
    SelectSecretTypeView(
        store: Store(initialState: SelectSecretTypeFeature.State()) {
            SelectSecretTypeFeature()
        }
    )
    .frame(width: 900, height: 600)
}

#Preview("탭 시 delegate 확인") {
    InteractiveSelectSecretTypePreview()
        .frame(width: 900, height: 640)
}

/// `SelectSecretTypeFeature`의 delegate가 실제로 부모까지 전달되는지 확인하기 위한 preview 전용 host reducer.
@Reducer
private struct PreviewHostFeature {

    @ObservableState
    struct State: Equatable {
        var child = SelectSecretTypeFeature.State()
        var lastSelected: CreatableSecretType?
    }

    enum Action: Equatable {
        case child(SelectSecretTypeFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.child, action: \.child) {
            SelectSecretTypeFeature()
        }
        Reduce { state, action in
            switch action {
            case .child(.delegate(.typeSelected(let type))):
                state.lastSelected = type
                return .none

            case .child:
                return .none
            }
        }
    }
}

private struct InteractiveSelectSecretTypePreview: View {

    private let store = Store(initialState: PreviewHostFeature.State()) {
        PreviewHostFeature()
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(store.lastSelected.map { "선택됨: \(String(localized: $0.displayName))" } ?? "아직 선택 안 함")
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.vaultGreen))
                .padding(.top, 16)

            SelectSecretTypeView(store: store.scope(state: \.child, action: \.child))
        }
    }
}

#endif
