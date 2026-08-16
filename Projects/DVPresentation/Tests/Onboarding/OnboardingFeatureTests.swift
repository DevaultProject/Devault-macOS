// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("OnboardingFeature")
struct OnboardingFeatureTests {

    @Test("didTapEnableTouchID는 인증에 성공하면 iCloud 단계로 넘어간다")
    func enableTouchIDSucceeds() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .security)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableTouchID = { }
        }

        await store.send(.didTapEnableTouchID)
        await store.receive(.touchIDAuthSucceeded) {
            $0.step = .icloudSync
        }
    }

    @Test("didTapEnableTouchID는 인증에 실패하면 alert를 띄우고 단계를 유지한다")
    func enableTouchIDShowsAlertOnFailure() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .security)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableTouchID = { throw UserAuthenticationError.failed }
        }

        await store.send(.didTapEnableTouchID)
        await store.receive(.touchIDAuthFailed(.failed)) {
            $0.alert = AlertState {
                TextState("Authentication failed")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please try again.")
            }
        }
    }

    @Test("didTapEnableSync는 iCloud 계정을 사용할 수 있으면 성공 스텝을 거쳐 온보딩을 완료한다")
    func enableSyncSucceeds() async {
        let clock = TestClock()
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.onboardingClient.enableICloudSync = { .available }
        }

        await store.send(.didTapEnableSync) {
            $0.isEnablingSync = true
        }
        await store.receive(.iCloudSyncStatusResponse(.available))
        await clock.advance(by: .seconds(0.5))
        await store.receive(.enableSyncCompleted) {
            $0.step = .syncEnabled
        }
        await clock.advance(by: .seconds(2))
        await store.receive(.delegate(.completed))
    }

    @Test("didTapEnableSync는 iCloud 계정이 없으면 재시도·계속·설정 열기 버튼이 있는 alert를 띄우고 되돌아간다")
    func enableSyncShowsAlertWhenNoAccount() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .noAccount }
            $0.onboardingClient.continueWithoutICloud = { }
        }

        await store.send(.didTapEnableSync) {
            $0.isEnablingSync = true
        }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.isEnablingSync = false
            $0.alert = AlertState {
                TextState("iCloud sync isn't available")
            } actions: {
                ButtonState(action: .retry) { TextState("Try Again") }
                ButtonState(action: .openSystemSettings) { TextState("Open System Settings") }
                ButtonState(action: .continueWithoutSync) { TextState("Continue Without iCloud") }
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Sign in to iCloud in System Settings, then try again.")
            }
        }
    }

    @Test("iCloud 계정 문제 alert에서 재시도를 누르면 다시 동기화를 시도한다")
    func retryButtonRetriesSync() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .noAccount }
            $0.onboardingClient.continueWithoutICloud = { }
        }

        await store.send(.didTapEnableSync) { $0.isEnablingSync = true }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.isEnablingSync = false
            $0.alert = makeNoAccountAlert()
        }
        await store.send(.alert(.presented(.retry))) {
            $0.alert = nil
        }
        await store.receive(.didTapEnableSync) { $0.isEnablingSync = true }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.isEnablingSync = false
            $0.alert = makeNoAccountAlert()
        }
    }

    @Test("iCloud 계정 문제 alert에서 계속을 누르면 온보딩을 완료 처리한다")
    func continueWithoutSyncCompletesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .noAccount }
            $0.onboardingClient.continueWithoutICloud = { }
        }

        await store.send(.didTapEnableSync) { $0.isEnablingSync = true }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.isEnablingSync = false
            $0.alert = makeNoAccountAlert()
        }
        await store.send(.alert(.presented(.continueWithoutSync))) {
            $0.alert = nil
            $0.isEnablingSync = true
        }
        await store.receive(.delegate(.completed))
    }

    @Test("iCloud 계정 문제 alert에서 설정 열기를 누르면 시스템 설정을 연다")
    func openSystemSettingsOpensSystemPreferences() async {
        let opened = LockIsolated(false)
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .noAccount }
            $0.onboardingClient.openICloudSystemSettings = { opened.setValue(true) }
        }

        await store.send(.didTapEnableSync) { $0.isEnablingSync = true }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.isEnablingSync = false
            $0.alert = makeNoAccountAlert()
        }
        await store.send(.alert(.presented(.openSystemSettings))) {
            $0.alert = nil
        }
        #expect(opened.value == true)
    }

    @Test("didTapNotNow는 온보딩을 완료 처리한다")
    func notNowCompletesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.continueWithoutICloud = { }
        }

        await store.send(.didTapNotNow) {
            $0.isEnablingSync = true
        }
        await store.receive(.delegate(.completed))
    }
}

private func makeNoAccountAlert() -> AlertState<OnboardingFeature.Action.Alert> {
    AlertState {
        TextState("iCloud sync isn't available")
    } actions: {
        ButtonState(action: .retry) { TextState("Try Again") }
        ButtonState(action: .openSystemSettings) { TextState("Open System Settings") }
        ButtonState(action: .continueWithoutSync) { TextState("Continue Without iCloud") }
        ButtonState(role: .cancel) { TextState("OK") }
    } message: {
        TextState("Sign in to iCloud in System Settings, then try again.")
    }
}
