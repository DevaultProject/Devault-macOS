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
                TextState("인증하지 못했어요")
            } actions: {
                ButtonState(role: .cancel) { TextState("확인") }
            } message: {
                TextState("다시 시도해주세요.")
            }
        }
    }

    @Test("didTapEnableSync는 iCloud 계정을 사용할 수 있으면 온보딩을 완료한다")
    func enableSyncSucceeds() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .available }
        }

        await store.send(.didTapEnableSync) {
            $0.step = .syncing
        }
        await store.receive(.iCloudSyncStatusResponse(.available))
        await store.receive(.syncingCompleted)
        await store.receive(.delegate(.completed))
    }

    @Test("didTapEnableSync는 iCloud 계정이 없으면 alert를 띄우고 되돌아간다")
    func enableSyncShowsAlertWhenNoAccount() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingClient.enableICloudSync = { .noAccount }
        }

        await store.send(.didTapEnableSync) {
            $0.step = .syncing
        }
        await store.receive(.iCloudSyncStatusResponse(.noAccount)) {
            $0.step = .icloudSync
            $0.alert = AlertState {
                TextState("iCloud 동기화를 사용할 수 없어요")
            } actions: {
                ButtonState(role: .cancel) { TextState("확인") }
            } message: {
                TextState("설정 앱에서 iCloud 로그인 후 다시 시도해주세요.")
            }
        }
    }

    @Test("didTapNotNow는 온보딩을 완료 처리한다")
    func notNowCompletesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .icloudSync)) {
            OnboardingFeature()
        }

        await store.send(.didTapNotNow)
        await store.receive(.delegate(.completed))
    }
}
