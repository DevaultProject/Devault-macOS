// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

// MARK: - ICloudSettingsFeature

@Reducer
public struct ICloudSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isSyncEnabled = false
    var isTogglingSync = false
    var lastSyncedAt: Date?
    var syncedSecretCount: Int?
    var syncedProjectCount: Int?
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapSyncNow

    // MARK: - Internal

    case enableSyncStatusResponse(ICloudAccountStatus)
    case remoteChangeDetected
    case countsResponse(secretCount: Int, projectCount: Int)
    case countsFailed
    case syncSettingResponse(enabled: Bool, succeeded: Bool)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    public enum Alert: Equatable {
      case retry
      case continueWithoutSync
      case openSystemSettings
    }
  }

  // MARK: - Dependencies

  @Dependency(\.iCloudSettingsClient) var iCloudSettingsClient
  @Dependency(\.date.now) var now

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isSyncEnabled = iCloudSettingsClient.isEnabled()
        state.lastSyncedAt = iCloudSettingsClient.lastSyncedAt()
        return .merge(
          refreshCountsEffect(),
          .run { send in
            for await _ in iCloudSettingsClient.remoteChangeStream() {
              await send(.remoteChangeDetected)
            }
          }
        )

      case .binding(\.isSyncEnabled):
        guard state.isSyncEnabled else {
          state.isTogglingSync = true
          return applySyncSettingEffect(false)
        }
        state.isTogglingSync = true
        return requestICloudAccountStatusEffect()

      case .enableSyncStatusResponse(let status):
        return handleEnableSyncStatusResponse(&state, status: status)

      case .binding:
        return .none

      case .didTapSyncNow:
        return refreshCountsEffect()

      case .remoteChangeDetected:
        state.lastSyncedAt = now
        return .merge(
          .run { [now] _ in iCloudSettingsClient.setLastSyncedAt(now) },
          refreshCountsEffect()
        )

      case .countsResponse(let secretCount, let projectCount):
        state.syncedSecretCount = secretCount
        state.syncedProjectCount = projectCount
        return .none

      case .countsFailed:
        state.syncedSecretCount = nil
        state.syncedProjectCount = nil
        return .none

      case let .syncSettingResponse(enabled, succeeded):
        state.isTogglingSync = false
        guard succeeded else {
          state.isSyncEnabled = !enabled
          if enabled {
            state.alert = makeICloudSyncUnavailableAlert(
              .configurationUnavailable,
              retry: .retry,
              continueWithoutSync: .continueWithoutSync,
              openSystemSettings: .openSystemSettings
            )
          }
          return .none
        }
        state.isSyncEnabled = enabled
        return .none

      case .alert(.presented(.retry)):
        state.isSyncEnabled = true
        state.isTogglingSync = true
        return requestICloudAccountStatusEffect()

      case .alert(.presented(.continueWithoutSync)):
        return .none

      case .alert(.presented(.openSystemSettings)):
        return .run { _ in iCloudSettingsClient.openSystemSettings() }

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

extension ICloudSettingsFeature {

  private enum CancelID {
    case refreshCounts
  }

  private func handleEnableSyncStatusResponse(
    _ state: inout State,
    status: ICloudAccountStatus
  ) -> Effect<Action> {
    guard status == .available else {
      state.isTogglingSync = false
      state.isSyncEnabled = false
      state.alert = makeICloudSyncUnavailableAlert(
        status,
        retry: .retry,
        continueWithoutSync: .continueWithoutSync,
        openSystemSettings: .openSystemSettings
      )
      return .none
    }
    return applySyncSettingEffect(true)
  }

  private func requestICloudAccountStatusEffect() -> Effect<Action> {
    .run { send in
      let status = await iCloudSettingsClient.accountStatus()
      await send(.enableSyncStatusResponse(status))
    }
  }

  private func applySyncSettingEffect(_ enabled: Bool) -> Effect<Action> {
    .run { send in
      do {
        try await iCloudSettingsClient.setEnabled(enabled)
        await send(.syncSettingResponse(enabled: enabled, succeeded: true))
      } catch {
        await send(.syncSettingResponse(enabled: enabled, succeeded: false))
      }
    }
  }

  /// iCloud가 꺼져 있어도 로컬 개수는 그대로 유효한 값이라 계속 보여준다 — 켜져 있을 때만
  /// "동기화된" 개수라는 의미가 더해질 뿐, 조회 자체는 항상 가능하다.
  private func refreshCountsEffect() -> Effect<Action> {
    .run { send in
      do {
        async let secretCount = iCloudSettingsClient.syncedSecretCount()
        async let projectCount = iCloudSettingsClient.syncedProjectCount()
        let (secrets, projects) = try await (secretCount, projectCount)
        await send(.countsResponse(secretCount: secrets, projectCount: projects))
      } catch is CancellationError {
      } catch {
        await send(.countsFailed)
      }
    }
    .cancellable(id: CancelID.refreshCounts, cancelInFlight: true)
  }
}
