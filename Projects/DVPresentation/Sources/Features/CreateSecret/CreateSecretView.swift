// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import ComposableArchitecture

// MARK: - CreateSecretView

struct CreateSecretView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<CreateSecretFeature>
    
    // MARK: - Body
    
    var body: some View {
        content
            .task { await store.send(.task).finish() }
    }
}

// MARK: - Subviews

extension CreateSecretView {
    
    private var content: some View {
        EmptyView()
    }
}

// MARK: - Preview

#Preview("API Keys/Token") {
    CreateSecretView(
        store: Store(initialState: CreateSecretFeature.State(secretType: .apiKeyToken)) {
            CreateSecretFeature()
        }
    )
}

#Preview("OAuth") {
    CreateSecretView(
        store: Store(initialState: CreateSecretFeature.State(secretType: .oauth)) {
            CreateSecretFeature()
        }
    )
}

#Preview("Database") {
    CreateSecretView(
        store: Store(initialState: CreateSecretFeature.State(secretType: .database)) {
            CreateSecretFeature()
        }
    )
}

