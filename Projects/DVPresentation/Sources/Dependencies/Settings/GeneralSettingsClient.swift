// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture

@DependencyClient
public struct GeneralSettingsClient: Sendable {
  public var isLaunchAtLoginEnabled: @Sendable () -> Bool = { false }
  /// 시스템 로그인 항목 변경에 성공한 뒤 설정을 저장한다. 실패하면 저장하지 않는다.
  public var setLaunchAtLoginEnabled: @Sendable (Bool) throws -> Void

  public var defaultEnvironment: @Sendable () -> String = { "dev" }
  public var setDefaultEnvironment: @Sendable (String) -> Void
}

extension GeneralSettingsClient: TestDependencyKey {
  public static let testValue = GeneralSettingsClient()

  public static let previewValue = GeneralSettingsClient(
    isLaunchAtLoginEnabled: { false },
    setLaunchAtLoginEnabled: { _ in },
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
