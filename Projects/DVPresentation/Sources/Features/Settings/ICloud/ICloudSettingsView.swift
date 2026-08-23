// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

struct ICloudSettingsView: View {

  @Bindable var store: StoreOf<ICloudSettingsFeature>

  var body: some View {
    content
      .task { await store.send(.task).finish() }
      .alert($store.scope(state: \.alert, action: \.alert))
  }
}

// MARK: - Subviews

extension ICloudSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: String.module("iCloud")) {
      SettingsSection(title: String.module("iCloud Sync")) {
        SettingsToggleRow(
          title: String.module("Use iCloud Sync"),
          description: String.module(
            "When enabled, data on this Mac is merged with iCloud. Turning it off keeps data in both places and stops future sync."
          ),
          isOn: $store.isSyncEnabled
        )
        // `.disabled`는 tint 스위치를 손잡이 없는 단색 캡슐로 그린다(렌더 버그). 상호작용만 막고 흐림으로 표시.
        // 잠긴 상태는 상호작용을 남겨 둔다 — 눌러야 페이월이 뜨고, 왜 못 켜는지 알 수 있다.
        .allowsHitTesting(!store.isTogglingSync)
        .opacity(store.isTogglingSync || store.isSyncLocked ? 0.6 : 1)

      }

      SettingsSection(title: String.module("Status")) {
        statusRows
      }
    }
  }

  @ViewBuilder
  private var statusRows: some View {
    if store.isSyncEnabled {
      SettingsButtonRow(
        title: connectionStatusTitle,
        buttonTitle: String.module("Refresh Status"),
        systemImage: connectionStatusSystemImage,
        iconColor: connectionStatusColor
      ) {
        store.send(.didTapRefreshStatus)
      }
      .disabled(store.isRefreshingStatus)
    } else {
      SettingsValueRow(
        title: String.module("Not Connected"),
        systemImage: "icloud.slash",
        iconColor: Color.dv(.gray500)
      )
    }

    if store.isSyncEnabled {
      SettingsValueRow(
        title: String.module("Last update detected"),
        value: store.lastUpdateDetectedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—"
      )
    } else {
      Text(.module("Turn on iCloud Sync to sync secrets across devices."))
        .dvFont(.captionMDRegular)
        .foregroundStyle(Color.dv(.gray600))
        .settingsRowLayout()
    }
  }

  private var connectionStatusTitle: String {
    switch store.accountStatus {
    case .some(.available):
      String.module("Connected")
    case .none where store.isRefreshingStatus:
      String.module("Checking Status…")
    case .none:
      String.module("Status Unavailable.")
    case .some(.noAccount):
      String.module("No iCloud Account")
    case .some(.restricted):
      String.module("iCloud Restricted")
    case .some(.temporarilyUnavailable):
      String.module("iCloud Temporarily Unavailable.")
    case .some(.networkUnavailable):
      String.module("Network Unavailable.")
    case .some(.configurationUnavailable):
      String.module("Storage Configuration Failed")
    case .some(.couldNotDetermine):
      String.module("Status Unavailable.")
    }
  }

  private var connectionStatusSystemImage: String {
    switch store.accountStatus {
    case .some(.available): "checkmark.icloud"
    case .none where store.isRefreshingStatus: "icloud"
    case .none, .some(_): "exclamationmark.icloud"
    }
  }

  private var connectionStatusColor: Color {
    switch store.accountStatus {
    case .some(.available): Color.dv(.vaultGreen)
    case .none where store.isRefreshingStatus: Color.dv(.gray500)
    case .none, .some(_): Color.dv(.warning)
    }
  }
}

// MARK: - Preview

#Preview("iCloud") {
  SettingsDetailPreview {
    ICloudSettingsView(
      store: Store(initialState: ICloudSettingsFeature.State()) {
        ICloudSettingsFeature()
      } withDependencies: {
        $0.iCloudSettingsClient = .previewValue
        $0.iCloudSettingsClient.isEnabled = { true }
        $0.iCloudSettingsClient.lastUpdateDetectedAt = {
          Date(timeIntervalSince1970: 1_723_745_800)
        }
      }
    )
  }
}
