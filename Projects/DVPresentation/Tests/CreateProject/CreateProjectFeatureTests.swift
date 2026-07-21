// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("CreateProjectFeature")
struct CreateProjectFeatureTests {

    @Test("didTapCreate는 이름이 비어 있으면 아무 일도 안 한다")
    func createIgnoresBlankName() async {
        let store = TestStore(initialState: CreateProjectFeature.State()) {
            CreateProjectFeature()
        }

        await store.send(.didChangeName("   ")) {
            $0.name = "   "
        }
        await store.send(.didTapCreate)
    }

    @Test("didTapCreate는 성공하면 delegate로 알리고 dismiss한다")
    func createSucceedsAndDismisses() async {
        let project = Project(id: UUID(), name: "DeVault", createdAt: .now, updatedAt: .now)
        var didDismiss = false
        let store = TestStore(initialState: CreateProjectFeature.State()) {
            CreateProjectFeature()
        } withDependencies: {
            $0.secretClient.createProject = { _ in project }
            $0.dismiss = DismissEffect { didDismiss = true }
        }

        await store.send(.didChangeName("DeVault")) {
            $0.name = "DeVault"
        }
        await store.send(.didTapCreate) {
            $0.isCreating = true
        }
        await store.receive(.createResponse(.success(project))) {
            $0.isCreating = false
        }
        await store.receive(.delegate(.projectCreated(project)))

        #expect(didDismiss)
    }

    @Test("didTapCancel은 dismiss한다")
    func cancelDismisses() async {
        var didDismiss = false
        let store = TestStore(initialState: CreateProjectFeature.State()) {
            CreateProjectFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { didDismiss = true }
        }

        await store.send(.didTapCancel)

        #expect(didDismiss)
    }
}
