// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("GeneralSettingsFeature")
struct GeneralSettingsFeatureTests {

    @Test("task는 현재 설정값을 읽어온다")
    func taskLoadsCurrentSettings() async {
        let store = TestStore(initialState: GeneralSettingsFeature.State()) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.settingsClient.isLaunchAtLoginEnabled = { true }
            $0.settingsClient.defaultEnvironment = { "prod" }
        }

        await store.send(.task) {
            $0.isLaunchAtLoginEnabled = true
            $0.defaultEnvironment = .prod
        }
    }

    @Test("로그인 시 자동 실행 등록이 실패하면 토글을 되돌린다")
    func launchAtLoginRevertsOnFailure() async {
        let store = TestStore(initialState: GeneralSettingsFeature.State(isLaunchAtLoginEnabled: false)) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setLaunchAtLoginEnabled = { _ in throw CancellationError() }
        }

        await store.send(.didToggleLaunchAtLogin(true)) {
            $0.isLaunchAtLoginEnabled = true
        }
        await store.receive(.launchAtLoginFailed(previousValue: false)) {
            $0.isLaunchAtLoginEnabled = false
        }
    }

    @Test("기본 환경을 선택하면 저장한다")
    func defaultEnvironmentSelectionPersists() async {
        let saved = LockIsolated<String?>(nil)
        let store = TestStore(initialState: GeneralSettingsFeature.State()) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setDefaultEnvironment = { saved.setValue($0) }
        }

        await store.send(.didSelectDefaultEnvironment(.staging)) {
            $0.defaultEnvironment = .staging
        }
        #expect(saved.value == "staging")
    }
}
