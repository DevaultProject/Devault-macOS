// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

// MARK: - NotificationSettingsFeature

@Reducer
public struct NotificationSettingsFeature {

  // MARK: - State

  @ObservableState
  public struct State: Equatable {
    var isExpiryAlertsEnabled = true
    var expiryAlertDaysBefore = Set(ExpiryAlertDay.allCases)
    var isAuthFailureAlertEnabled = true
    var isClipboardAbnormalAccessAlertEnabled = true
    var isNotificationPermissionGranted = true
    /// 무료 등급이라 시점을 하나만 고를 수 있는 상태. 뷰가 잠금 표시에 쓴다.
    var isMultipleAlertDaysLocked = false
    @Presents var alert: AlertState<Action.Alert>?

    public init() {}
  }

  // MARK: - Action

  public enum Action: BindableAction, Equatable {

    // MARK: - View

    case binding(BindingAction<State>)
    case task
    case didTapExpiryAlertDay(ExpiryAlertDay)
    case didTapOpenNotificationSettings

    // MARK: - Delegate

    case delegate(Delegate)

    public enum Delegate: Equatable {
      /// 무료 등급이라 시점을 여러 개 고를 수 없다. 페이월은 상위가 소유하므로 올려보낸다.
      case paywallRequired
    }

    // MARK: - Internal

    case permissionResponse(Bool)
    case expiryNotificationsUpdateFailed
    case entitlementChanged(Entitlement)

    // MARK: - Child

    case alert(PresentationAction<Alert>)

    public enum Alert: Equatable {}
  }

  // MARK: - Dependencies

  @Dependency(\.notificationSettingsClient) var notificationSettingsClient
  @Dependency(\.entitlementClient) var entitlementClient

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        state.isExpiryAlertsEnabled = notificationSettingsClient.isExpiryAlertsEnabled()
        state.expiryAlertDaysBefore = Set(notificationSettingsClient.expiryAlertDaysBefore())
        state.isMultipleAlertDaysLocked = !entitlementClient.canUseMultipleExpiryAlertDays()
        state.isAuthFailureAlertEnabled = notificationSettingsClient.isAuthFailureAlertEnabled()
        state.isClipboardAbnormalAccessAlertEnabled = notificationSettingsClient.isClipboardAbnormalAccessAlertEnabled()
        let clampEffect = clampExpiryAlertDaysIfLocked(&state)
        return .merge(
          .run { send in
            let granted = await notificationSettingsClient.isPermissionGranted()
            await send(.permissionResponse(granted))
          },
          // 페이월이 이 화면 위에서 뜨므로, 결제 직후 화면이 잠긴 표시로 남지 않으려면 등급을 구독해야 한다.
          .run { send in
            for await entitlement in entitlementClient.stream() {
              await send(.entitlementChanged(entitlement))
            }
          },
          clampEffect
        )

      case .delegate:
        return .none

      case .entitlementChanged:
        state.isMultipleAlertDaysLocked = !entitlementClient.canUseMultipleExpiryAlertDays()
        return clampExpiryAlertDaysIfLocked(&state)

      case .permissionResponse(let granted):
        state.isNotificationPermissionGranted = granted
        return .none

      case .binding(\.isExpiryAlertsEnabled):
        let enabled = state.isExpiryAlertsEnabled
        return .run { send in
          do {
            try await notificationSettingsClient.setExpiryAlertsEnabled(enabled)
          } catch {
            await send(.expiryNotificationsUpdateFailed)
          }
        }

      case .binding(\.isAuthFailureAlertEnabled):
        let enabled = state.isAuthFailureAlertEnabled
        return .run { _ in notificationSettingsClient.setAuthFailureAlertEnabled(enabled) }

      case .binding(\.isClipboardAbnormalAccessAlertEnabled):
        let enabled = state.isClipboardAbnormalAccessAlertEnabled
        return .run { _ in notificationSettingsClient.setClipboardAbnormalAccessAlertEnabled(enabled) }

      case .binding:
        return .none

      case .expiryNotificationsUpdateFailed:
        state.alert = AlertState {
          TextState(String.module("Couldn't update expiration alerts."))
        } actions: {
          ButtonState(role: .cancel) { TextState(String.module("OK")) }
        } message: {
          TextState(String.module("The setting was saved, but existing notifications couldn't be updated. Please try again."))
        }
        return .none

      case .didTapExpiryAlertDay(let day):
        if state.expiryAlertDaysBefore.contains(day) {
          state.expiryAlertDaysBefore.remove(day)
        } else {
          // 무료는 하나만 고를 수 있다. 이미 고른 것이 있으면 바꾸는 게 아니라 막는다 — 조용히 갈아끼우면 사용자가 왜 이전 선택이 사라졌는지 알 수 없다.
          if !entitlementClient.canUseMultipleExpiryAlertDays(), !state.expiryAlertDaysBefore.isEmpty {
            return .send(.delegate(.paywallRequired))
          }
          state.expiryAlertDaysBefore.insert(day)
        }
        let days = state.expiryAlertDaysBefore.sorted { $0.rawValue > $1.rawValue }
        return .run { send in
          do {
            try await notificationSettingsClient.setExpiryAlertDaysBefore(days)
          } catch {
            await send(.expiryNotificationsUpdateFailed)
          }
        }

      case .didTapOpenNotificationSettings:
        return .run { _ in notificationSettingsClient.openSystemSettings() }

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Free 등급 알림 시점 제한

extension NotificationSettingsFeature {

  /// Free 등급인데 시점이 2개 이상(또는 7일이 아닌 1개) 선택돼 있으면 7일로 맞춘다.
  ///
  /// **화면에 보이는 선택과 실제 예약이 어긋나면 안 된다.** 예약 쪽(`ScheduleSecretExpiryNotificationsUseCaseImpl`)은
  /// 이미 Free를 가장 이른 시점 하나로 트리밍해서 보내지만, 설정 화면은 저장된 값을 그대로 보여주기만 해서
  /// 기본값(전체 선택)이나 예전 Pro 시절 선택이 체크된 채로 남아 있었다 — 실제로는 하나만 울리는데 여러 개가
  /// 켜진 것처럼 보인다. 7일을 고른 이유는 무료 한도(``EntitlementLimits/maxExpiryAlertDays``)의 기본값으로
  /// 가장 무난한 시점이기 때문이다.
  private func clampExpiryAlertDaysIfLocked(_ state: inout State) -> Effect<Action> {
    guard state.isMultipleAlertDaysLocked,
          state.expiryAlertDaysBefore != [.sevenDaysBefore]
    else {
      return .none
    }
    state.expiryAlertDaysBefore = [.sevenDaysBefore]
    return .run { send in
      do {
        try await notificationSettingsClient.setExpiryAlertDaysBefore([.sevenDaysBefore])
      } catch {
        await send(.expiryNotificationsUpdateFailed)
      }
    }
  }
}
