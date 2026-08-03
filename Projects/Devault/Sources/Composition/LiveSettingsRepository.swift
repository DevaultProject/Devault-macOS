// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain

/// Composition Root에서 공유하는 SettingsRepository 단일 인스턴스.
enum LiveSettingsRepository {
  static let shared: any SettingsRepository = SettingsRepositoryImpl()
}
