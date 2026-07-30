// Copyright © 2026 Devault. All rights reserved

import OSLog
import DVData
import DVDomain

/// Composition Root에서 공유하는 ModelContainer 단일 인스턴스.
/// SecretRepositoryImpl, ProjectRepositoryImpl이 동일 컨테이너를 참조해야 한다.
enum LiveStorage {
  private static let logger = Logger(subsystem: "com.devault", category: "LiveStorage")

  static let shared: LocalStorage = {
    do {
      let settingsRepository: any SettingsRepository = SettingsRepositoryImpl()
      return try LocalStorage.makeDefault(iCloudSyncEnabled: settingsRepository.isICloudSyncEnabled())
    } catch {
      logger.critical("LocalStorage 초기화 실패: \(error, privacy: .public)")
      fatalError("LocalStorage 초기화 실패 — 앱을 재시작하거나 데이터를 복원하세요.\n\(error)")
    }
  }()
}
