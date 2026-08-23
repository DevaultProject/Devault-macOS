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
    /// 무료 등급이라 동기화를 켤 수 없는 상태. 뷰가 잠금 표시에 쓴다.
    var isSyncLocked = false
    var isTogglingSync = false
    var isRefreshingStatus = false
    var accountStatus: ICloudAccountStatus?
    var lastUpdateDetectedAt: Date?
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapRefreshStatus

    // MARK: - Internal

    case enableSyncStatusResponse(ICloudAccountStatus)
    case refreshStatusResponse(ICloudAccountStatus)
    case remoteChangeDetected
    case syncSettingResponse(enabled: Bool, succeeded: Bool)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Alert: Equatable {
      case retryEnable
      case retryDisable
      case retryRefreshStatus
      case confirmDisableSync
      case continueWithoutSync
      case openSystemSettings
    }

    public enum Delegate: Equatable {
      case storageDidSwitch
      /// 무료 등급이라 동기화를 켤 수 없다. 페이월은 상위가 소유하므로 올려보낸다.
      case paywallRequired
    }
  }

  // MARK: - Dependencies

  @Dependency(\.iCloudSettingsClient) var iCloudSettingsClient
  @Dependency(\.entitlementClient) var entitlementClient
  @Dependency(\.date.now) var now

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isSyncEnabled = iCloudSettingsClient.isEnabled()
        state.isSyncLocked = !entitlementClient.canEnableICloudSync()
        state.lastUpdateDetectedAt = iCloudSettingsClient.lastUpdateDetectedAt()
        state.isRefreshingStatus = state.isSyncEnabled
        return .merge(
          state.isSyncEnabled ? requestRefreshStatusEffect() : .none,
          .run { send in
            for await _ in iCloudSettingsClient.remoteChangeStream() {
              await send(.remoteChangeDetected)
            }
          }
        )

      case .binding(\.isSyncEnabled):
        guard state.isSyncEnabled else {
          state.isSyncEnabled = true
          state.alert = disableSyncConfirmationAlert
          return .none
        }
        // 끄는 것은 등급과 무관하게 허용한다. 켜는 것만 막는다.
        guard entitlementClient.canEnableICloudSync() else {
          state.isSyncEnabled = false
          return .send(.delegate(.paywallRequired))
        }
        state.isTogglingSync = true
        return requestICloudAccountStatusEffect()

      case .enableSyncStatusResponse(let status):
        return handleEnableSyncStatusResponse(&state, status: status)

      case .refreshStatusResponse(let status):
        state.isRefreshingStatus = false
        state.accountStatus = status
        guard status != .available else { return .none }
        state.alert = makeICloudSyncUnavailableAlert(
          status,
          retry: .retryRefreshStatus,
          continueWithoutSync: nil,
          openSystemSettings: .openSystemSettings
        )
        return .none

      case .binding:
        return .none

      case .didTapRefreshStatus:
        guard state.isSyncEnabled, !state.isRefreshingStatus else { return .none }
        state.isRefreshingStatus = true
        return requestRefreshStatusEffect()

      case .remoteChangeDetected:
        // 표시만 즉시 갱신한다. 영속화는 상시 동작하는 AppFeature의 원격 변경 핸들러가 단독으로 맡아,
        // 같은 값을 두 곳에서 쓰던 중복을 없앤다.
        state.lastUpdateDetectedAt = now
        return .none

      case let .syncSettingResponse(enabled, succeeded):
        state.isTogglingSync = false
        guard succeeded else {
          state.isSyncEnabled = !enabled
          state.accountStatus = .configurationUnavailable
          state.alert = makeICloudSyncUnavailableAlert(
            .configurationUnavailable,
            retry: enabled ? .retryEnable : .retryDisable,
            continueWithoutSync: enabled ? .continueWithoutSync : nil,
            openSystemSettings: .openSystemSettings
          )
          return .none
        }
        state.isSyncEnabled = enabled
        state.accountStatus = enabled ? .available : nil
        return .send(.delegate(.storageDidSwitch))

      case .alert(.presented(.retryEnable)):
        state.isSyncEnabled = true
        state.isTogglingSync = true
        return requestICloudAccountStatusEffect()

      case .alert(.presented(.retryDisable)):
        state.isSyncEnabled = false
        state.isTogglingSync = true
        return applySyncSettingEffect(false)

      case .alert(.presented(.retryRefreshStatus)):
        state.isRefreshingStatus = true
        return requestRefreshStatusEffect()

      case .alert(.presented(.confirmDisableSync)):
        state.isSyncEnabled = false
        state.isTogglingSync = true
        return applySyncSettingEffect(false)

      case .alert(.presented(.continueWithoutSync)):
        return .none

      case .alert(.presented(.openSystemSettings)):
        return .run { _ in iCloudSettingsClient.openSystemSettings() }

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Private

extension ICloudSettingsFeature {

  private var disableSyncConfirmationAlert: AlertState<Action.Alert> {
    AlertState {
      TextState(String.module("Turn Off iCloud Sync?"))
    } actions: {
      ButtonState(role: .destructive, action: .confirmDisableSync) {
        TextState(String.module("Turn Off"))
      }
      ButtonState(role: .cancel) {
        TextState(String.module("Cancel"))
      }
    } message: {
      TextState(
        String.module(
          "Data on this Mac and in iCloud won't be deleted. Future changes on this Mac won't sync until iCloud Sync is turned on again."
        )
      )
    }
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
        retry: .retryEnable,
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

  private func requestRefreshStatusEffect() -> Effect<Action> {
    .run { send in
      let status = await iCloudSettingsClient.accountStatus()
      await send(.refreshStatusResponse(status))
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

}
