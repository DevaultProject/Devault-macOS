// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

/// `DevaultProSettingsView`의 업그레이드 버튼에서 여는 시트.
///
/// 가격 문자열은 `SubscriptionProduct`가 StoreKit에서 로케일에 맞춰 이미 포맷해 온 값이다 —
/// 여기서 통화·자릿수를 다시 계산하지 않는다.
struct DevaultProPaywallView: View {

  // MARK: - Properties

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  @Dependency(\.purchaseClient) private var purchaseClient

  @State private var products: [SubscriptionProduct] = []
  @State private var selectedProductID: String?
  @State private var isPurchasing = false
  @State private var isRestoring = false
  @State private var errorMessage: String?
  /// 이미 구독 중인 채로 열리면 카피와 버튼 문구가 "가입"이 아니라 "변경"이어야 한다.
  @State private var isChangingPlan = false
  /// 현재 구독 중인 상품 ID. 이 값과 같은 플랜을 선택하면 "변경"이 성립하지 않으므로 버튼을 막는다.
  @State private var currentProductID: String?

  // MARK: - Body

  var body: some View {
    content
      .task {
        let status = await purchaseClient.subscriptionStatus()
        isChangingPlan = status.entitlement == .pro
        currentProductID = status.productID
        await loadProducts()
      }
  }

  private var isBusy: Bool { isPurchasing || isRestoring }
  private var selectedProduct: SubscriptionProduct? {
    products.first { $0.id == selectedProductID }
  }
  private var isSelectingCurrentPlan: Bool {
    selectedProductID != nil && selectedProductID == currentProductID
  }

  /// `vaultGreenTint` 배경 위에 놓이는 아이콘·배지 글자색.
  ///
  /// 라이트 모드에서는 옅은 tint 위에 `vaultGreen`이 또렷하지만, 다크모드의 `vaultGreenTint`는
  /// 옅은 색이 아니라 채도 있는 진초록(#1A6B50)이라 같은 계열인 `vaultGreen`과 명도차가 거의
  /// 없다. 다크모드에서는 흰색으로 바꿔 대비를 확보한다.
  private var accentOnTint: Color {
    colorScheme == .dark ? Color.dv(.white) : Color.dv(.vaultGreen)
  }
}

// MARK: - Subviews

extension DevaultProPaywallView {

  private var content: some View {
    VStack(spacing: 20) {
      header

      HStack(alignment: .top, spacing: 24) {
        featureList
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        planGrid
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }

      if let errorMessage {
        Text(errorMessage)
          .dvFont(.captionMDRegular)
          .foregroundStyle(Color.dv(.danger))
          .multilineTextAlignment(.center)
      }

      subscribeButton
        .padding(.top, 8)
      footer
    }
    .padding(24)
    .frame(width: 880)
  }

  /// 닫기 버튼을 별도 행으로 두면 그 줄만큼 위가 비어 보인다 — 코너에 얹어서
  /// 배지·타이틀이 시트 맨 위에서 바로 시작하게 한다.
  private var header: some View {
    VStack(spacing: 12) {
      iconBadge

      VStack(spacing: 6) {
        Text(isChangingPlan ? String.module("Change Your Plan") : String.module("Upgrade to DeVault Pro"))
          .dvFont(.headingLG)
          .foregroundStyle(Color.dv(.gray900))
        Text(.module("Manage your secrets more securely on every device, without the 15-item limit."))
          .dvFont(.bodyMD)
          .foregroundStyle(Color.dv(.gray600))
          .multilineTextAlignment(.center)
          // fixedSize가 없으면 VStack이 제안하는 높이에 맞춰 한 줄로 줄여버려 "…"로 잘린다.
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity)
    .overlay(alignment: .topTrailing) {
      DVIconButton(
        systemName: "xmark",
        idle: .gray500,
        hovered: .gray700,
        pressed: .gray800
      ) {
        dismiss()
      }
      .accessibilityLabel(String.module("Close"))
    }
  }

  private var iconBadge: some View {
    Circle()
      .fill(Color.dv(.vaultGreenTint))
      .frame(width: 56, height: 56)
      .overlay(
        Image(systemName: "crown")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(accentOnTint)
      )
  }

  /// 오른쪽 플랜 카드 열이 더 길면 이 열의 남는 높이를 행 사이 `Spacer`가 흡수해
  /// 두 열의 전체 높이가 맞아떨어지도록 한다 — 고정 spacing 값을 추측해 넣는 대신
  /// 실제 남는 만큼만 나눠 갖는다.
  private var featureList: some View {
    VStack(spacing: 0) {
      ForEach(Array(DevaultProFeature.all.enumerated()), id: \.element.id) { index, feature in
        featureRow(feature)
        if index < DevaultProFeature.all.count - 1 {
          Spacer(minLength: 12)
        }
      }
    }
  }

  private func featureRow(_ feature: DevaultProFeature) -> some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.dv(.vaultGreenTint))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: feature.systemImage)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(accentOnTint)
        )
      VStack(alignment: .leading, spacing: 2) {
        Text(feature.title)
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
        Text(feature.description)
          .dvFont(.bodyMD)
          .foregroundStyle(Color.dv(.gray600))
      }
      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private var planGrid: some View {
    if products.isEmpty {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      VStack(spacing: 10) {
        ForEach(products) { product in
          planCard(product)
        }
      }
    }
  }

  private func planCard(_ product: SubscriptionProduct) -> some View {
    let isSelected = product.id == selectedProductID

    return DVRadioButton(isSelected: isSelected, action: { selectedProductID = product.id }) {
      HStack(alignment: .center) {
        Text(product.displayName)
          .dvFont(.bodyLG)
          .foregroundStyle(Color.dv(.gray900))
        Spacer(minLength: 12)
        priceText(for: product)
          .dvFont(.bodyLG)
      }
      // DVRadioButton 내부 인디케이터-라벨 간격(3pt)이 좁아 카드 안에서는 답답해 보인다 —
      // 컴포넌트를 고치는 대신 라벨 쪽에서 여유를 더 준다.
      .padding(.leading, 4)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    // 미선택 카드는 채우지 않고 테두리만 그린다 — 회색으로 채우면 라이트/다크 어느 쪽이든
    // 밋밋하고 탁해 보인다. 선택 카드만 tint로 채워서 시선을 끈다.
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(isSelected ? Color.dv(.vaultGreenTint) : Color.clear)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(isSelected ? Color.dv(.vaultGreen) : Color.dv(.gray300), lineWidth: isSelected ? 1.5 : 1)
    )
    // DVRadioButton 자체의 탭 영역은 인디케이터+라벨에만 붙어 있어 패딩(카드 여백)을 누르면
    // 반응하지 않는다 — 카드 전체를 눌러도 선택되도록 별도로 씌운다.
    .contentShape(Rectangle())
    .onTapGesture { selectedProductID = product.id }
  }

  private var subscribeButton: some View {
    DVButton(titleText: subscribeButtonTitle, style: .primary) {
      Task { await purchase() }
    }
    .disabled(selectedProduct == nil || isBusy || isSelectingCurrentPlan)
    .frame(maxWidth: .infinity)
  }

  private var footer: some View {
    VStack(spacing: 8) {
      Text(footerText)
        .dvFont(.captionMDRegular)
        .foregroundStyle(Color.dv(.gray500))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 12) {
        // 이용약관 전용 URL이 아직 없어 Privacy Policy와 같은 페이지로 임시 연결한다.
        // 실제 이용약관 URL이 정해지면 여기만 교체하면 된다.
        Link(String.module("Terms of Service"), destination: HelpMenuLink.privacyPolicy.url)
          .underline()
        Link(String.module("Privacy Policy"), destination: HelpMenuLink.privacyPolicy.url)
          .underline()
        Button(String.module("Restore Purchase")) {
          Task { await restore() }
        }
        .buttonStyle(.plain)
        .underline()
        .disabled(isBusy)
      }
      .dvFont(.captionMDRegular)
      .foregroundStyle(Color.dv(.gray500))
    }
  }
}

// MARK: - Formatting

extension DevaultProPaywallView {

  /// 1개월 요금제는 `monthlyEquivalentPrice`가 없어(전체가와 같으므로) 총액만 보여준다.
  /// 총액 부분만 더 진하게 보이도록 `Text`를 이어붙인다 — 하나의 문자열로 합치면
  /// 부분별로 다른 색을 줄 수 없다.
  private func priceText(for product: SubscriptionProduct) -> Text {
    guard let monthlyEquivalentPrice = product.monthlyEquivalentPrice else {
      return Text(product.displayPrice).foregroundStyle(Color.dv(.gray600))
    }

    let monthly = Text(String(format: String.module("%@/mo"), monthlyEquivalentPrice))
      .foregroundStyle(Color.dv(.gray600))
    let total = Text(String(format: String.module("Total %@"), product.displayPrice))
      .foregroundStyle(Color.dv(.gray700))
      .fontWeight(.semibold)

    return monthly + Text(" · ").foregroundStyle(Color.dv(.gray600)) + total
  }

  private var subscribeButtonTitle: String {
    guard let selectedProduct else {
      return isChangingPlan ? String.module("Change Plan") : String.module("Subscribe")
    }
    if isSelectingCurrentPlan {
      return String.module("Your Current Plan")
    }
    return isChangingPlan
      ? String(format: String.module("Change to %@"), selectedProduct.displayName)
      : String(format: String.module("Subscribe for %@"), selectedProduct.displayName)
  }

  private var footerText: String {
    String.module(
      "Automatically renews after the period ends. You can cancel anytime in Settings."
    )
  }
}

// MARK: - Actions

extension DevaultProPaywallView {

  private func loadProducts() async {
    do {
      let loaded = try await purchaseClient.products()
      products = loaded
      if selectedProductID == nil {
        // 플랜 변경이면 지금 쓰고 있는 플랜을 그대로 보여준다 — 아무것도 안 눌러도 "다른 플랜"을
        // 고르라는 화면인지 알 수 있어야 한다. 신규 가입이면 1개월(가장 짧은 구독, 정렬 기준 첫 항목)을 기본값으로 둔다.
        selectedProductID = currentProductID ?? loaded.first?.id
      }
    } catch {
      errorMessage = String.module("Couldn't load subscription plans. Check your connection and try again.")
    }
  }

  private func purchase() async {
    guard let selectedProduct else { return }
    isPurchasing = true
    defer { isPurchasing = false }
    errorMessage = nil
    do {
      let result = try await purchaseClient.purchase(productID: selectedProduct.id)
      switch result {
      case .success:
        dismiss()
      case .userCancelled:
        break
      case .pending:
        errorMessage = String.module("Your purchase is pending approval.")
      }
    } catch {
      errorMessage = String.module("Purchase failed. Please try again.")
    }
  }

  private func restore() async {
    isRestoring = true
    defer { isRestoring = false }
    errorMessage = nil
    do {
      try await purchaseClient.restore()
      dismiss()
    } catch {
      errorMessage = String.module("Couldn't restore your purchase. Please try again.")
    }
  }
}

// MARK: - Preview

#Preview("Devault Pro Paywall") {
  DevaultProPaywallView()
}
