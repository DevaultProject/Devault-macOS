// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("SecuritySettingsFeature")
struct SecuritySettingsFeatureTests {

    @Test("task는 현재 설정값을 읽어온다")
    func taskLoadsCurrentSettings() async {
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.isRequireAuthOnLaunchEnabled = { false }
            $0.settingsClient.isRequireAuthToCopyEnabled = { false }
        }

        await store.send(.task) {
            $0.isRequireAuthOnLaunchEnabled = false
            $0.isRequireAuthToCopyEnabled = false
        }
    }

    @Test("앱 실행 시 인증 요구 토글을 저장한다")
    func requireAuthOnLaunchTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.setRequireAuthOnLaunchEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleRequireAuthOnLaunch(false)) {
            $0.isRequireAuthOnLaunchEnabled = false
        }
        #expect(saved.value == false)
    }

    @Test("복사 시 인증 요구 토글을 저장한다")
    func requireAuthToCopyTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.setRequireAuthToCopyEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleRequireAuthToCopy(false)) {
            $0.isRequireAuthToCopyEnabled = false
        }
        #expect(saved.value == false)
    }
}
