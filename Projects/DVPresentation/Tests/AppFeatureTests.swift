// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("AppFeature")
struct AppFeatureTests {

    @Test("task는 온보딩을 완료했으면 locked 상태로 시작한다")
    func taskStartsLockedWhenOnboardingCompleted() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { }
        }

        await store.send(.task) {
            $0.locked = .init()
        }
    }

    @Test("main의 lockRequested delegate는 main을 지우고 locked를 새로 연다")
    func lockRequestedLocksApp() async {
        var initial = AppFeature.State()
        initial.main = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        }

        await store.send(.main(.didTapLock))
        await store.receive(.main(.delegate(.lockRequested))) {
            $0.main = nil
            $0.locked = .init()
        }
    }
}
