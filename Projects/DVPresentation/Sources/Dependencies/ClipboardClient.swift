// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture

/// 민감한 값을 클립보드에 복사하는 Client. 자동 정리·반복 복사 감지는 DVDomain의
/// `CopySensitiveValueUseCase`가 담당하고, 여기서는 wiring만 한다.
@DependencyClient
public struct ClipboardClient: Sendable {
  public var copy: @Sendable (String) async throws -> Void
}

extension ClipboardClient: TestDependencyKey {
  public static let testValue = ClipboardClient()

  public static let previewValue = ClipboardClient(
    copy: { _ in }
  )
}

extension DependencyValues {
  public var clipboardClient: ClipboardClient {
    get { self[ClipboardClient.self] }
    set { self[ClipboardClient.self] = newValue }
  }
}
