// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

/// 구독 상태 업셀/관리 화면. 등급과 갱신 정보는 `PurchaseClient`가 StoreKit에서 읽어 온다.
struct DevaultProSettingsView: View {

  private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

  /// 실제 시크릿 개수·한도는 목록/카운트 작업이 머지된 뒤 채운다. 머지 전까지 가짜 숫자를
  /// 보여주면 실제 사용량으로 오해하므로, 값이 없는 동안은 사용량 표시 자체를 비워 둔다.
  private let usage: (used: Int, limit: Int)? = nil

  @Dependency(\.purchaseClient) private var purchaseClient
  @Dependency(\.entitlementClient) private var entitlementClient

  @State private var subscriptionStatus: DVDomain.SubscriptionStatus = .free
  @State private var isShowingPaywall = false

  var body: some View {
    content
      .sheet(isPresented: $isShowingPaywall) {
        DevaultProPaywallView()
      }
      .task {
        // 갱신·환불·복원으로 등급이 바뀔 때마다 다시 읽는다. 스트림이 구독 즉시 현재값을
        // 한 번 방출하므로 최초 로드도 이 하나로 해결된다.
        for await _ in entitlementClient.stream() {
          subscriptionStatus = await purchaseClient.subscriptionStatus()
        }
      }
  }
}

// MARK: - Subviews

extension DevaultProSettingsView {

  private var content: some View {
    SettingsDetailContainer(title: "Devault Pro") {
      SettingsSection(title: .module("Current Plan")) {
        currentPlanRow
      }

      SettingsSection(title: .module("What You Get with Pro")) {
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

  private var isPro: Bool { subscriptionStatus.entitlement == .pro }

  private var currentPlanRow: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(isPro ? SettingsCategory.devaultPro.title : String.module("Free Plan"))
              .dvFont(.bodyLG)
              .foregroundStyle(Color.dv(.gray900))
            DVChip(String.module("Current Plan"))
          }
          if isPro, let renewalDescription {
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
        if isPro {
          HStack(spacing: 8) {
            // secondary/secondaryProminent는 같은 지오메트리를 공유해 나란히 둬도 크기가 어긋나지 않는다.
            // macOS StoreKit에는 iOS의 manageSubscriptionsSheet(isPresented:) 같은 인앱 시트가 없다 —
            // App Store의 구독 관리 페이지를 직접 연다.
            DVButton(titleText: .module("Manage Subscription"), style: .secondary) {
              NSWorkspace.shared.open(Self.manageSubscriptionsURL)
            }
            DVButton(titleText: .module("Change Plan"), style: .secondaryProminent) {
              isShowingPaywall = true
            }
          }
        } else {
          DVButton(titleText: .module("Upgrade to Devault Pro"), style: .primarySmall) {
            isShowingPaywall = true
          }
        }
      }
      if !isPro, let usage {
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
    guard let renewsAt = subscriptionStatus.renewsAt else { return nil }
    let dateText = renewsAt.formatted(date: .abbreviated, time: .omitted)
    return subscriptionStatus.willAutoRenew
      ? String(format: String.module("Renews on %@"), dateText)
      : String(format: String.module("Expires on %@"), dateText)
  }
}

// MARK: - Preview

#Preview("Devault Pro") {
  SettingsDetailPreview {
    DevaultProSettingsView()
  }
}
