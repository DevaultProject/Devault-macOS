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
}

extension SettingsClient: TestDependencyKey {
  public static let testValue = SettingsClient()

  public static let previewValue = SettingsClient(
    isLaunchAtLoginEnabled: { false },
    setLaunchAtLoginEnabled: { _ in },
    defaultEnvironment: { nil },
    setDefaultEnvironment: { _ in }
  )
}

extension DependencyValues {
  public var settingsClient: SettingsClient {
    get { self[SettingsClient.self] }
    set { self[SettingsClient.self] = newValue }
  }
}
