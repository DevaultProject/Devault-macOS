// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("NotificationSettingsFeature")
struct NotificationSettingsFeatureTests {

    @Test("task는 현재 설정값과 알림 권한 상태를 읽어온다")
    func taskLoadsCurrentSettingsAndPermission() async {
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.isExpiryAlertsEnabled = { false }
            $0.settingsClient.expiryAlertDaysBefore = { [7, 1] }
            $0.settingsClient.isAuthFailureAlertEnabled = { false }
            $0.settingsClient.isClipboardAbnormalAccessAlertEnabled = { false }
            $0.settingsClient.isNotificationPermissionGranted = { false }
        }

        await store.send(.task) {
            $0.isExpiryAlertsEnabled = false
            $0.expiryAlertDaysBefore = [7, 1]
            $0.isAuthFailureAlertEnabled = false
            $0.isClipboardAbnormalAccessAlertEnabled = false
        }
        await store.receive(.permissionResponse(false)) {
            $0.isNotificationPermissionGranted = false
        }
    }

    @Test("만료 알림 사용 토글을 저장한다")
    func expiryAlertsTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setExpiryAlertsEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleExpiryAlerts(false)) {
            $0.isExpiryAlertsEnabled = false
        }
        #expect(saved.value == false)
    }

    @Test("만료 알림 타이밍 선택을 저장한다")
    func expiryAlertDaysBeforePersists() async {
        let saved = LockIsolated<[Int]?>(nil)
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setExpiryAlertDaysBefore = { saved.setValue($0) }
        }

        await store.send(.didChangeExpiryAlertDaysBefore([7])) {
            $0.expiryAlertDaysBefore = [7]
        }
        #expect(saved.value == [7])
    }

    @Test("반복 인증 실패 알림 토글을 저장한다")
    func authFailureAlertTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setAuthFailureAlertEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleAuthFailureAlert(false)) {
            $0.isAuthFailureAlertEnabled = false
        }
        #expect(saved.value == false)
    }

    @Test("클립보드 비정상 접근 알림 토글을 저장한다")
    func clipboardAbnormalAccessAlertTogglePersists() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setClipboardAbnormalAccessAlertEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleClipboardAbnormalAccessAlert(false)) {
            $0.isClipboardAbnormalAccessAlertEnabled = false
        }
        #expect(saved.value == false)
    }

    @Test("시스템 알림 설정 열기를 요청하면 딥링크를 연다")
    func openNotificationSettingsCallsDeepLink() async {
        let opened = LockIsolated(false)
        let store = TestStore(initialState: NotificationSettingsFeature.State()) {
            NotificationSettingsFeature()
        } withDependencies: {
            $0.settingsClient.openNotificationSystemSettings = { opened.setValue(true) }
        }

        await store.send(.didTapOpenNotificationSettings)
        #expect(opened.value)
    }
}
