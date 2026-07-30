// Copyright © 2026 Devault. All rights reserved

import Foundation

enum UbiquitousStoreKey: String {
  case isICloudSyncEnabled
}

extension NSUbiquitousKeyValueStore {
  func bool(forKey key: UbiquitousStoreKey) -> Bool {
    bool(forKey: key.rawValue)
  }

  func set(_ value: Bool, forKey key: UbiquitousStoreKey) {
    set(value, forKey: key.rawValue)
    synchronize()
  }
}
