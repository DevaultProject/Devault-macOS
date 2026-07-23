// Copyright © 2026 Devault. All rights reserved

import Foundation

enum UserDefaultsKey: String {
  case hasCompletedOnboarding
}

extension UserDefaults {
  func bool(forKey key: UserDefaultsKey) -> Bool {
    bool(forKey: key.rawValue)
  }

  func set(_ value: Bool, forKey key: UserDefaultsKey) {
    set(value, forKey: key.rawValue)
  }
}
