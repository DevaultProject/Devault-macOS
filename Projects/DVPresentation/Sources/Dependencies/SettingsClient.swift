// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

/// Settings 화면 전용 Client. 카테고리별로 메서드를 늘려간다.
@DependencyClient
public struct SettingsClient: Sendable {

  // MARK: - General

  public var isLaunchAtLoginEnabled: @Sendable () -> Bool = { false }
  /// 로그인 항목 등록/해제(SMAppService)까지 수행한 뒤 설정을 저장한다. 실패하면 저장하지 않는다.
  public var setLaunchAtLoginEnabled: @Sendable (Bool) throws -> Void

  public var defaultEnvironment: @Sendable () -> String? = { nil }
  public var setDefaultEnvironment: @Sendable (String?) -> Void

  // MARK: - Security

  public var isRequireAuthOnLaunchEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthOnLaunchEnabled: @Sendable (Bool) -> Void

  public var isRequireAuthToCopyEnabled: @Sendable () -> Bool = { true }
  public var setRequireAuthToCopyEnabled: @Sendable (Bool) -> Void

  /// 비활성 후 자동 잠금까지의 시간(분). 0이면 "사용 안 함".
  public var autoLockMinutes: @Sendable () -> Int = { 5 }
  public var setAutoLockMinutes: @Sendable (Int) -> Void
}

extension SettingsClient: TestDependencyKey {
  public static let testValue = SettingsClient()

  public static let previewValue = SettingsClient(
    isLaunchAtLoginEnabled: { false },
    setLaunchAtLoginEnabled: { _ in },
    defaultEnvironment: { nil },
    setDefaultEnvironment: { _ in },
    isRequireAuthOnLaunchEnabled: { true },
    setRequireAuthOnLaunchEnabled: { _ in },
    isRequireAuthToCopyEnabled: { true },
    setRequireAuthToCopyEnabled: { _ in },
    autoLockMinutes: { 5 },
    setAutoLockMinutes: { _ in }
  )
}

extension DependencyValues {
  public var settingsClient: SettingsClient {
    get { self[SettingsClient.self] }
    set { self[SettingsClient.self] = newValue }
  }
}
