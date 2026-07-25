// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

// MARK: - SelectSecretTypeFeature

@Reducer
public struct SelectSecretTypeFeature {

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    // MARK: - Action

    public enum Action: Equatable {

        // MARK: - View

        case didSelectType(CreatableSecretType)

        // MARK: - Delegate

        case delegate(Delegate)

        public enum Delegate: Equatable {
            case typeSelected(CreatableSecretType)
        }
    }

    // MARK: - Init

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
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
