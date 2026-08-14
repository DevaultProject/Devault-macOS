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

    @Test("task는 온보딩을 완료했으면 만료 알림을 동기화한다")
    func taskSyncsExpiryNotificationsWhenOnboardingCompleted() async {
        let synced = LockIsolated(false)
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { synced.setValue(true) }
        }

        await store.send(.task) {
            $0.locked = .init()
        }

        #expect(synced.value)
    }

    // syncExpiryNotifications가 LiveRepositories.secret을 처음 건드려 ModelContainer를 그 순간의 iCloud 설정으로 고정시키므로, 아직 Secret이 없는 온보딩 전에는 건너뛴다.
    @Test("task는 온보딩 전이면 만료 알림 동기화를 건너뛴다")
    func taskSkipsExpiryNotificationsBeforeOnboarding() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { false }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            // syncExpiryNotifications를 오버라이드하지 않는다 — 호출되면 @DependencyClient의
            // unimplemented 클로저가 테스트를 실패시킨다.
        }

        await store.send(.task) {
            $0.onboarding = .init()
        }
    }

    @Test("task는 앱 실행 시 인증 요구가 꺼져 있으면 잠금 없이 바로 main으로 시작한다")
    func taskStartsMainWhenRequireAuthOnLaunchDisabled() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { }
            $0.settingsClient.isRequireAuthOnLaunchEnabled = { false }
        }

        await store.send(.task) {
            $0.main = .init()
        }
    }

    @Test("유휴 시간이 자동 잠금 설정을 넘으면 main에서 locked로 전환한다")
    func idleTimeoutLocksApp() async {
        var initial = AppFeature.State()
        initial.main = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.settingsClient.autoLockMinutes = { 5 }
        }

        await store.send(.idleTimeoutReached) {
            $0.main = nil
            $0.locked = .init()
        }
    }

    @Test("main이 아닐 때는 유휴 시간이 넘어도 아무 전환도 하지 않는다")
    func idleTimeoutIgnoredWhenNotInMain() async {
        var initial = AppFeature.State()
        initial.locked = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        }

        await store.send(.idleTimeoutReached)
    }

    @Test("task 중 유휴 시간이 자동 잠금 설정을 넘으면 idleTimeoutReached를 보낸다")
    func taskWatchesIdleTimeAndSendsTimeout() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { }
            $0.settingsClient.autoLockMinutes = { 5 }
            $0.idleMonitorClient.idleSecondsStream = {
                AsyncStream { continuation in
                    continuation.yield(400)
                    continuation.finish()
                }
            }
        }

        await store.send(.task) {
            $0.locked = .init()
        }
        await store.receive(.idleTimeoutReached)
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
