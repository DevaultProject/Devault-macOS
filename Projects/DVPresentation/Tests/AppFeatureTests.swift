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
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.appSecurityClient.isRequireAuthOnLaunchEnabled = { true }
            $0.windowCaptureBlockerClient.enabledStream = { AsyncStream { $0.finish() } }
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
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.appSecurityClient.isRequireAuthOnLaunchEnabled = { true }
            $0.windowCaptureBlockerClient.enabledStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.task) {
            $0.locked = .init()
        }

        #expect(synced.value)
    }

    // 온보딩에서 iCloud 사용 여부를 고르기 전에는 저장소를 지연 초기화한다.
    @Test("task는 온보딩 전이면 만료 알림 동기화를 건너뛴다")
    func taskSkipsExpiryNotificationsBeforeOnboarding() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { false }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.windowCaptureBlockerClient.enabledStream = { AsyncStream { $0.finish() } }
            // syncExpiryNotifications를 오버라이드하지 않는다 — 호출되면 @DependencyClient의
            // unimplemented 클로저가 테스트를 실패시킨다.
        }

        await store.send(.task) {
            $0.onboarding = .init()
        }
    }

    @Test("온보딩 완료 후 현재 저장소의 만료 알림을 동기화한다")
    func onboardingCompletionSyncsExpiryNotifications() async {
        let completed = LockIsolated(false)
        let synced = LockIsolated(false)
        var initial = AppFeature.State()
        initial.onboarding = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.setOnboardingCompleted = { completed.setValue(true) }
            $0.appLaunchClient.syncExpiryNotifications = { synced.setValue(true) }
            $0.appSecurityClient.inactivityTimeoutStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.onboarding(.delegate(.completed))) {
            $0.onboarding = nil
            $0.main = .init()
        }
        await store.finish()

        #expect(completed.value)
        #expect(synced.value)
    }

    @Test("task는 앱 실행 시 인증 요구가 꺼져 있으면 잠금 없이 바로 main으로 시작한다")
    func taskStartsMainWhenRequireAuthOnLaunchDisabled() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { }
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.appSecurityClient.isRequireAuthOnLaunchEnabled = { false }
            $0.appSecurityClient.inactivityTimeoutStream = { AsyncStream { $0.finish() } }
            $0.windowCaptureBlockerClient.enabledStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.task) {
            $0.main = .init()
        }
    }

    @Test("앱 비활성 타임아웃이 발생하면 main에서 locked로 전환한다")
    func inactivityTimeoutLocksApp() async {
        var initial = AppFeature.State()
        initial.main = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        }

        await store.send(.inactivityTimeoutReached) {
            $0.main = nil
            $0.locked = .init()
        }
    }

    @Test("main이 아닐 때는 앱 비활성 타임아웃을 무시한다")
    func inactivityTimeoutIgnoredWhenNotInMain() async {
        var initial = AppFeature.State()
        initial.locked = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        }

        await store.send(.inactivityTimeoutReached)
    }

    @Test("task 중 앱 비활성 타임아웃이 발생하면 inactivityTimeoutReached를 보낸다")
    func taskWatchesInactivityAndSendsTimeout() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { true }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.syncExpiryNotifications = { }
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.appSecurityClient.isRequireAuthOnLaunchEnabled = { false }
            $0.appSecurityClient.inactivityTimeoutStream = {
                AsyncStream { continuation in
                    continuation.yield(())
                    continuation.finish()
                }
            }
            $0.windowCaptureBlockerClient.enabledStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.task) {
            $0.main = .init()
        }
        await store.receive(.inactivityTimeoutReached) {
            $0.main = nil
            $0.locked = .init()
        }
    }

    @Test("task는 화면 캡처 차단 설정 변경을 State에 반영한다")
    func taskWatchesWindowCaptureBlockingSetting() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.appLaunchClient.hasCompletedOnboarding = { false }
            $0.appLaunchClient.requestNotificationAuthorization = { true }
            $0.appLaunchClient.iCloudRemoteChangeStream = { AsyncStream { $0.finish() } }
            $0.windowCaptureBlockerClient.enabledStream = {
                AsyncStream { continuation in
                    continuation.yield(false)
                    continuation.finish()
                }
            }
        }

        await store.send(.task) {
            $0.onboarding = .init()
        }
        await store.receive(.windowCaptureBlockingChanged(false)) {
            $0.isWindowCaptureBlockingEnabled = false
        }
    }

    @Test("iCloud 원격 변경은 debounce 후 만료 알림을 다시 동기화한다")
    func iCloudRemoteChangeSyncsExpiryNotifications() async {
        let clock = TestClock()
        let synced = LockIsolated(false)
        let savedDate = LockIsolated<Date?>(nil)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var initial = AppFeature.State()
        initial.locked = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.date = .constant(date)
            $0.appLaunchClient.syncExpiryNotifications = { synced.setValue(true) }
            $0.appLaunchClient.setICloudLastSyncedAt = { savedDate.setValue($0) }
        }

        await store.send(.iCloudRemoteChangeDetected)
        await clock.advance(by: .seconds(1))
        await store.receive(.iCloudRemoteChangeHandled)

        #expect(synced.value)
        #expect(savedDate.value == date)
    }

    @Test("잠금 해제하면 새 앱 비활성 감시를 시작한다")
    func unlockStartsNewInactivityMonitoring() async {
        var initial = AppFeature.State()
        initial.locked = .init()

        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.appSecurityClient.inactivityTimeoutStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.locked(.delegate(.unlockCompleted))) {
            $0.locked = nil
            $0.main = .init()
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
