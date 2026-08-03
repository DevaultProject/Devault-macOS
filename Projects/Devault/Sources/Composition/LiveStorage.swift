// Copyright © 2026 Devault. All rights reserved

import OSLog
import DVData
import DVDomain

/// Composition Root에서 공유하는 ModelContainer 단일 인스턴스.
enum LiveStorage {
  private static let logger = Logger(subsystem: "com.devault", category: "LiveStorage")

  // shared는 static let이라 앱 실행 중 isICloudSyncEnabled가 바뀌어도 이미 만들어진 ModelContainer에는 반영되지 않는다.
  // TODO: Settings 화면에서 토글을 지원하려면 재시작 안내를 띄우거나, ModelContainer를 런타임에 재생성하는 hot-swap이 필요하다.
  static let shared: LocalStorage = {
    do {
      return try LocalStorage.makeDefault(iCloudSyncEnabled: LiveSettingsRepository.shared.isICloudSyncEnabled())
    } catch {
      logger.critical("LocalStorage 초기화 실패: \(error, privacy: .public)")
      fatalError("LocalStorage 초기화 실패 — 앱을 재시작하거나 데이터를 복원하세요.\n\(error)")
    }
  }()
}
