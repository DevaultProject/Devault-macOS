// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SelectSecretTypeFeature

@Reducer
struct SelectSecretTypeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        init() {}
    }

    // MARK: - Action

    enum Action: Equatable {

        // MARK: - View

        case didSelectType(CreatableSecretType)

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate: Equatable {
            case typeSelected(CreatableSecretType)
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didSelectType(let type):
                return .send(.delegate(.typeSelected(type)))

            case .delegate:
                return .none
            }
        }
    }
}
