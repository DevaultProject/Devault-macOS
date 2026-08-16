// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 자동 잠금 시간(분)을 표현하는 Presentation VO.
enum AutoLockInterval: Int, CaseIterable, Hashable {
  case oneMinute = 1
  case threeMinutes = 3
  case fiveMinutes = 5
  case fifteenMinutes = 15
  case thirtyMinutes = 30

  var displayName: LocalizedStringResource {
    .module("\(rawValue) min")
  }
}

/// 클립보드 자동 비우기 지연 시간(초)을 표현하는 Presentation VO.
enum ClipboardClearDelay: Int, CaseIterable, Hashable {
  case fifteenSeconds = 15
  case thirtySeconds = 30
  case oneMinute = 60
  case fiveMinutes = 300

  var displayName: LocalizedStringResource {
    if rawValue < 60 {
      .module("\(rawValue) sec")
    } else {
      .module("\(rawValue / 60) min")
    }
  }
}
