// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

/// 구독 상태 업셀/관리 화면. 등급과 갱신 정보는 `DevaultProSettingsFeature`가 `PurchaseClient`로 StoreKit에서 읽어 온다.
struct DevaultProSettingsView: View {

  @Bindable var store: StoreOf<DevaultProSettingsFeature>

  /// 카운트를 아직 못 읽어 온 동안은(로딩 중) 가짜 숫자로 오해하지 않도록 사용량 표시 자체를 비워 둔다.
  private var usage: (used: Int, limit: Int)? {
    guard let count = store.secretCount else { return nil }
    return (count, EntitlementLimits.maxSecrets)
  }

  var body: some View {
    content
      .sheet(item: $store.scope(state: \.paywall, action: \.paywall)) { paywallStore in
        DevaultProPaywallView(store: paywallStore)
      }
      .task { await store.send(.task).finish() }
  }
}

// MARK: - Subviews

extension DevaultProSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: "DeVault Pro") {
      SettingsSection(title: .module("Current Plan")) {
        currentPlanRow
      }

      // Pro면 이미 누리고 있는 혜택이라 "얻을 수 있는"이 아니라 "누리고 있는" 어조로 바꾼다.
      SettingsSection(title: store.isPro ? String.module("Your Pro Benefits") : String.module("What You Get with Pro")) {
        ForEach(DevaultProFeature.all) { feature in
          SettingsValueRow(
            title: feature.title,
            description: feature.description,
            systemImage: feature.systemImage,
            iconColor: Color.dv(.vaultGreen)
          )
        }
      }
    }
  }

  private var currentPlanRow: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 4) {
          Text(store.isPro ? (store.currentPlanName ?? SettingsCategory.devaultPro.title) : String.module("Free Plan"))
            .dvFont(.bodyLG)
            .foregroundStyle(Color.dv(.gray900))
          if store.isPro, let renewalDescription {
            Text(renewalDescription)
              .dvFont(.captionMDRegular)
              .foregroundStyle(Color.dv(.gray600))
          } else if let usage {
            Text(usageDescription(usage))
              .dvFont(.captionMDRegular)
              .foregroundStyle(Color.dv(.gray600))
          }
        }
        Spacer(minLength: 12)
        if store.isPro {
          HStack(spacing: 8) {
            // secondary/secondaryProminent는 같은 지오메트리를 공유해 나란히 둬도 크기가 어긋나지 않는다.
            // macOS StoreKit에는 iOS의 manageSubscriptionsSheet(isPresented:) 같은 인앱 시트가 없다 —
            // App Store의 구독 관리 페이지를 직접 연다.
            DVButton(titleText: .module("Manage Subscription"), style: .secondary) {
              store.send(.didTapManageSubscription)
            }
            DVButton(titleText: .module("Change Plan"), style: .secondaryProminent) {
              store.send(.didTapChangePlan)
            }
          }
        } else {
          DVButton(titleText: .module("Upgrade to DeVault Pro"), style: .primarySmall) {
            store.send(.didTapUpgrade)
          }
        }
      }
      if !store.isPro, let usage {
        ProgressView(value: Double(usage.used), total: Double(usage.limit))
          .tint(Color.dv(.vaultGreen))
      }
    }
    .settingsRowLayout()
  }

  private func usageDescription(_ usage: (used: Int, limit: Int)) -> String {
    String(format: String.module("%lld of %lld secrets used"), usage.used, usage.limit)
  }

  private var renewalDescription: String? {
    guard let renewsAt = store.subscriptionStatus.renewsAt else { return nil }
    let dateText = renewsAt.formatted(date: .abbreviated, time: .omitted)
    return store.subscriptionStatus.willAutoRenew
      ? String(format: String.module("Renews on %@"), dateText)
      : String(format: String.module("Expires on %@"), dateText)
  }
}

// MARK: - Preview

#Preview("Devault Pro") {
  SettingsDetailPreview {
    DevaultProSettingsView(
      store: Store(initialState: DevaultProSettingsFeature.State()) {
        DevaultProSettingsFeature()
      }
    )
  }
}
