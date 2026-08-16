// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

@DependencyClient
public struct GeneralSettingsClient: Sendable {
  public var launchAtLoginStatus: @Sendable () -> LaunchAtLoginStatus = { .notRegistered }
  /// 시스템 로그인 항목 변경에 성공한 뒤 설정을 저장한다. 실패하면 저장하지 않는다.
  public var setLaunchAtLoginEnabled: @Sendable (Bool) throws -> LaunchAtLoginStatus
  public var openLoginItemsSystemSettings: @Sendable () -> Void

  public var defaultEnvironment: @Sendable () -> String = { "dev" }
  public var setDefaultEnvironment: @Sendable (String) -> Void
}

extension GeneralSettingsClient: TestDependencyKey {
  public static let testValue = GeneralSettingsClient()

  public static let previewValue = GeneralSettingsClient(
    launchAtLoginStatus: { .notRegistered },
    setLaunchAtLoginEnabled: { _ in .notRegistered },
    openLoginItemsSystemSettings: { },
    defaultEnvironment: { "dev" },
    setDefaultEnvironment: { _ in }
  )
}

extension DependencyValues {
  public var generalSettingsClient: GeneralSettingsClient {
    get { self[GeneralSettingsClient.self] }
    set { self[GeneralSettingsClient.self] = newValue }
  }
}
