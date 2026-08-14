// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - ICloudSettingsFeature

@Reducer
struct ICloudSettingsFeature {

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    var isSyncEnabled = false
    var isTogglingSync = false
    var lastSyncedAt: Date?
    var syncedSecretCount: Int?
    var syncedProjectCount: Int?
    /// 토글 직후 앱을 재시작해야 실제로 반영된다는 안내. `LiveStorage`가 앱 실행 중 재구성되지
    /// 않기 때문 — 후속 이슈(런타임 hot-swap) 전까지의 임시 UX.
    var showsRestartBanner = false
    @Presents var alert: AlertState<Action.Alert>?
  }

  // MARK: - Action

  enum Action: Equatable {
    case task
    case didToggleSync(Bool)
    case enableSyncStatusResponse(ICloudAccountStatus)
    case didTapSyncNow
    case remoteChangeDetected
    case countsResponse(secretCount: Int, projectCount: Int)
    case alert(PresentationAction<Alert>)

    enum Alert: Equatable {
      case retry
      case continueWithoutSync
      case openSystemSettings
    }
  }

  // MARK: - Dependencies

  @Dependency(\.settingsClient) var settingsClient
  @Dependency(\.iCloudSyncStatusClient) var iCloudSyncStatusClient
  @Dependency(\.date.now) var now

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        state.isSyncEnabled = settingsClient.isICloudSyncEnabled()
        state.lastSyncedAt = iCloudSyncStatusClient.lastSyncedAt()
        return .merge(
          refreshCountsEffect(),
          .run { send in
            for await _ in iCloudSyncStatusClient.remoteChangeStream() {
              await send(.remoteChangeDetected)
            }
          }
        )

      case .didToggleSync(let enabled):
        guard enabled else {
          state.isSyncEnabled = false
          state.showsRestartBanner = true
          return .run { _ in settingsClient.setICloudSyncEnabled(false) }
        }
        state.isTogglingSync = true
        return .run { send in
          let status = await iCloudSyncStatusClient.accountStatus()
          await send(.enableSyncStatusResponse(status))
        }

      case .enableSyncStatusResponse(let status):
        state.isTogglingSync = false
        guard status == .available else {
          state.alert = makeICloudSyncUnavailableAlert(
            status,
            retry: .retry,
            continueWithoutSync: .continueWithoutSync,
            openSystemSettings: .openSystemSettings
          )
          return .none
        }
        state.isSyncEnabled = true
        state.showsRestartBanner = true
        return .run { _ in settingsClient.setICloudSyncEnabled(true) }

      case .didTapSyncNow:
        return refreshCountsEffect()

      case .remoteChangeDetected:
        state.lastSyncedAt = now
        return .merge(
          .run { [now] _ in iCloudSyncStatusClient.setLastSyncedAt(now) },
          refreshCountsEffect()
        )

      case .countsResponse(let secretCount, let projectCount):
        state.syncedSecretCount = secretCount
        state.syncedProjectCount = projectCount
        return .none

      case .alert(.presented(.retry)):
        return .send(.didToggleSync(true))

      case .alert(.presented(.continueWithoutSync)):
        return .none

      case .alert(.presented(.openSystemSettings)):
        return .run { _ in settingsClient.openICloudSystemSettings() }

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

private extension ICloudSettingsFeature {
  /// iCloud가 꺼져 있어도 로컬 개수는 그대로 유효한 값이라 계속 보여준다 — 켜져 있을 때만
  /// "동기화된" 개수라는 의미가 더해질 뿐, 조회 자체는 항상 가능하다.
  func refreshCountsEffect() -> Effect<Action> {
    .run { send in
      do {
        async let secretCount = iCloudSyncStatusClient.syncedSecretCount()
        async let projectCount = iCloudSyncStatusClient.syncedProjectCount()
        let (secrets, projects) = try await (secretCount, projectCount)
        await send(.countsResponse(secretCount: secrets, projectCount: projects))
      } catch is CancellationError {
      } catch {
        // 카운트 조회 실패는 카드에 값만 비워두고 조용히 무시한다 — 동기화 자체를 막을 이유가 아니다.
      }
    }
  }
}
