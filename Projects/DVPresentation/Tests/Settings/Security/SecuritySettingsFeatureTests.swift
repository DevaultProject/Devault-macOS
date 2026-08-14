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
            $0.settingsClient.autoLockMinutes = { 15 }
        }

        await store.send(.task) {
            $0.isRequireAuthOnLaunchEnabled = false
            $0.isRequireAuthToCopyEnabled = false
            $0.autoLockMinutes = 15
        }
    }

    @Test("자동 잠금 시간을 선택하면 저장한다")
    func autoLockMinutesSelectionPersists() async {
        let saved = LockIsolated<Int?>(nil)
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.setAutoLockMinutes = { saved.setValue($0) }
        }

        await store.send(.didSelectAutoLockMinutes(0)) {
            $0.autoLockMinutes = 0
        }
        #expect(saved.value == 0)
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

    @Test("클립보드 자동 비우기 토글을 저장한다")
    func autoClearClipboardTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.setAutoClearClipboardEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleAutoClearClipboard(false)) {
            $0.isAutoClearClipboardEnabled = false
        }
        #expect(saved.value == false)
    }

    @Test("클립보드 자동 비우기 시간을 선택하면 저장한다")
    func autoClearClipboardDelaySelectionPersists() async {
        let saved = LockIsolated<Int?>(nil)
        let store = TestStore(initialState: SecuritySettingsFeature.State()) {
            SecuritySettingsFeature()
        } withDependencies: {
            $0.settingsClient.setAutoClearClipboardDelaySeconds = { saved.setValue($0) }
        }

        await store.send(.didSelectAutoClearClipboardDelay(60)) {
            $0.autoClearClipboardDelaySeconds = 60
        }
        #expect(saved.value == 60)
    }
}
