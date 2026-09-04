// Copyright © 2026 Devault. All rights reserved

/// Pro 혜택 하나. `DevaultProSettingsView`(설정 탭)와 `DevaultProPaywallView`(업그레이드 시트)가
/// 같은 목록을 보여줘야 해서 여기 하나로 모아둔다 — 각자 따로 들면 한쪽만 바뀌었을 때 조용히 어긋난다.
struct DevaultProFeature: Identifiable {
  let id: String
  let title: String
  let description: String
  let systemImage: String

  static let all: [DevaultProFeature] = [
    DevaultProFeature(
      id: "unlimitedSecrets",
      title: .module("Unlimited Secrets"),
      description: .module("Save as many secrets as you need, without the 15-item limit."),
      systemImage: "infinity"
    ),
    DevaultProFeature(
      id: "unlimitedProjects",
      title: .module("Unlimited Projects"),
      description: .module("Create as many projects as you need, without the 1-project limit."),
      systemImage: "folder"
    ),
    DevaultProFeature(
      id: "sync",
      title: .module("Sync Across Devices"),
      description: .module("Always up to date on Mac."),
      systemImage: "arrow.triangle.2.circlepath"
    ),
    DevaultProFeature(
      id: "expiryAlerts",
      title: .module("Expiry Alerts"),
      description: .module("Get notified before a secret expires."),
      systemImage: "bell.badge"
    ),
  ]
}
