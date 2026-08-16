// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
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
      $0.notificationSettingsClient.isExpiryAlertsEnabled = { false }
      $0.notificationSettingsClient.expiryAlertDaysBefore = { [7, 1] }
      $0.notificationSettingsClient.isAuthFailureAlertEnabled = { false }
      $0.notificationSettingsClient.isClipboardAbnormalAccessAlertEnabled = { false }
      $0.notificationSettingsClient.isPermissionGranted = { false }
    }

    await store.send(.task) {
      $0.isExpiryAlertsEnabled = false
      $0.expiryAlertDaysBefore = [.sevenDaysBefore, .oneDayBefore]
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
      $0.notificationSettingsClient.setExpiryAlertsEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isExpiryAlertsEnabled, false))) {
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
      $0.notificationSettingsClient.setExpiryAlertDaysBefore = { saved.setValue($0) }
    }

    await store.send(.didTapExpiryAlertDay(.thirtyDaysBefore)) {
      $0.expiryAlertDaysBefore = [.sevenDaysBefore, .oneDayBefore, .expirationDay]
    }
    #expect(saved.value == [7, 1, 0])
  }

  @Test("반복 인증 실패 알림 토글을 저장한다")
  func authFailureAlertTogglePersists() async {
    let saved = LockIsolated<Bool?>(nil)
    let store = TestStore(initialState: NotificationSettingsFeature.State()) {
      NotificationSettingsFeature()
    } withDependencies: {
      $0.notificationSettingsClient.setAuthFailureAlertEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isAuthFailureAlertEnabled, false))) {
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
      $0.notificationSettingsClient.setClipboardAbnormalAccessAlertEnabled = { saved.setValue($0) }
    }

    await store.send(.binding(.set(\.isClipboardAbnormalAccessAlertEnabled, false))) {
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
      $0.notificationSettingsClient.openSystemSettings = { opened.setValue(true) }
    }

    await store.send(.didTapOpenNotificationSettings)
    #expect(opened.value)
  }
}
