// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("LockFeature")
struct LockFeatureTests {

    @Test("didTapUnlock은 인증에 성공하면 delegate로 알린다")
    func unlockSucceeds() async {
        let store = TestStore(initialState: LockFeature.State()) {
            LockFeature()
        } withDependencies: {
            $0.lockClient.unlock = { }
        }

        await store.send(.didTapUnlock)
        await store.receive(.unlockAuthSucceeded)
        await store.receive(.delegate(.unlockCompleted))
    }

    @Test("didTapUnlock은 인증에 실패하면 alert를 띄운다")
    func unlockShowsAlertOnFailure() async {
        let store = TestStore(initialState: LockFeature.State()) {
            LockFeature()
        } withDependencies: {
            $0.lockClient.unlock = { throw UserAuthenticationError.failed }
        }

        await store.send(.didTapUnlock)
        await store.receive(.unlockAuthFailed(.failed)) {
            $0.alert = AlertState {
                TextState("Unlock failed")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please try again.")
            }
        }
    }
}
