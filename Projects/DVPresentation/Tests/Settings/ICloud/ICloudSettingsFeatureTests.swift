// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation
import Testing

@testable import DVPresentation

@MainActor
@Suite("ICloudSettingsFeature")
struct ICloudSettingsFeatureTests {

    @Test("task는 현재 설정값을 읽고 카운트를 조회한다")
    func taskLoadsCurrentSettings() async {
        let store = TestStore(initialState: ICloudSettingsFeature.State()) {
            ICloudSettingsFeature()
        } withDependencies: {
            $0.settingsClient.isICloudSyncEnabled = { true }
            $0.iCloudSyncStatusClient.lastSyncedAt = { nil }
            $0.iCloudSyncStatusClient.syncedSecretCount = { 3 }
            $0.iCloudSyncStatusClient.syncedProjectCount = { 1 }
            $0.iCloudSyncStatusClient.remoteChangeStream = { AsyncStream { $0.finish() } }
        }

        await store.send(.task) {
            $0.isSyncEnabled = true
        }
        await store.receive(.countsResponse(secretCount: 3, projectCount: 1)) {
            $0.syncedSecretCount = 3
            $0.syncedProjectCount = 1
        }
    }

    @Test("동기화 켜기가 성공하면 설정을 저장하고 재시작 안내를 띄운다")
    func enableSyncSucceeds() async {
        let store = TestStore(initialState: ICloudSettingsFeature.State()) {
            ICloudSettingsFeature()
        } withDependencies: {
            $0.iCloudSyncStatusClient.accountStatus = { .available }
            $0.settingsClient.setICloudSyncEnabled = { _ in }
        }

        await store.send(.didToggleSync(true)) {
            $0.isTogglingSync = true
        }
        await store.receive(.enableSyncStatusResponse(.available)) {
            $0.isTogglingSync = false
            $0.isSyncEnabled = true
            $0.showsRestartBanner = true
        }
    }

    @Test("동기화 켜기가 실패하면 alert를 띄운다")
    func enableSyncFailsShowsAlert() async {
        let store = TestStore(initialState: ICloudSettingsFeature.State()) {
            ICloudSettingsFeature()
        } withDependencies: {
            $0.iCloudSyncStatusClient.accountStatus = { .noAccount }
        }

        await store.send(.didToggleSync(true)) {
            $0.isTogglingSync = true
        }
        await store.receive(.enableSyncStatusResponse(.noAccount)) {
            $0.isTogglingSync = false
            $0.alert = makeICloudSyncUnavailableAlert(
                .noAccount,
                retry: .retry,
                continueWithoutSync: .continueWithoutSync,
                openSystemSettings: .openSystemSettings
            )
        }
    }

    @Test("동기화 끄기는 계정 확인 없이 바로 저장하고 재시작 안내를 띄운다")
    func disableSyncSkipsAccountCheck() async {
        let saved = LockIsolated<Bool?>(nil)
        var initial = ICloudSettingsFeature.State()
        initial.isSyncEnabled = true

        let store = TestStore(initialState: initial) {
            ICloudSettingsFeature()
        } withDependencies: {
            $0.settingsClient.setICloudSyncEnabled = { saved.setValue($0) }
        }

        await store.send(.didToggleSync(false)) {
            $0.isSyncEnabled = false
            $0.showsRestartBanner = true
        }
        #expect(saved.value == false)
    }

    @Test("원격 변경이 감지되면 마지막 동기화 시각을 저장하고 카운트를 다시 조회한다")
    func remoteChangeUpdatesLastSyncedAtAndCounts() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let savedDate = LockIsolated<Date?>(nil)
        let store = TestStore(initialState: ICloudSettingsFeature.State()) {
            ICloudSettingsFeature()
        } withDependencies: {
            $0.date = .constant(fixedDate)
            $0.iCloudSyncStatusClient.setLastSyncedAt = { savedDate.setValue($0) }
            $0.iCloudSyncStatusClient.syncedSecretCount = { 5 }
            $0.iCloudSyncStatusClient.syncedProjectCount = { 2 }
        }

        await store.send(.remoteChangeDetected) {
            $0.lastSyncedAt = fixedDate
        }
        await store.receive(.countsResponse(secretCount: 5, projectCount: 2)) {
            $0.syncedSecretCount = 5
            $0.syncedProjectCount = 2
        }
        #expect(savedDate.value == fixedDate)
    }
}
