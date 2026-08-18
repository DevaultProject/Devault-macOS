// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// `SettingsRepository.appearance`(String)에 `rawValue`로 저장되는 Presentation VO.
/// 앱 전체에 적용할 색 구성(시스템/라이트/다크)을 나타낸다.
public enum AppAppearance: String, CaseIterable, Hashable, Sendable {
  case system
  case light
  case dark

  /// Appearance picker의 옵션 라벨. DVPresentation 모듈의 String Catalog 룩업 대상.
  var displayName: LocalizedStringResource {
    switch self {
    case .system: return .module("System")
    case .light:  return .module("Light")
    case .dark:   return .module("Dark")
    }
  }

  /// 루트 뷰에 적용할 색 구성. `.system`이면 nil을 반환해 macOS 시스템 설정을 따른다.
  public var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light:  return .light
    case .dark:   return .dark
    }
  }
}
