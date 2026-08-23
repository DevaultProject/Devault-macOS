// Copyright © 2026 Devault. All rights reserved

#if DEBUG
import SwiftUI

import ComposableArchitecture
import DVDomain

/// 결제 도메인을 눈으로 확인하기 위한 **데모용 페이월**이다.
///
/// **트랙 2가 만들 진짜 페이월(B2)이 아니다.** 디자인·카피·심사 요건(자동 갱신 고지·복원 버튼 배치·EULA 링크)을 하나도 지키지 않는다. 여기 있는 것은 `PurchaseService`와 `EntitlementUseCase`가 실제로 물려 돌아가는지 보기 위한 계기판이고, 진짜 페이월이 올라오면 이 파일은 지운다.
///
/// DEBUG 전용이라 릴리스 빌드에는 컴파일되지 않는다. 상품을 보려면 `./scripts/generate-storekit`으로 로컬 테스트 스토어를 스킴에 붙여야 한다.
public struct DebugPaywallView: View {

    @Environment(\.dismiss) private var dismiss

    @Dependency(\.entitlementClient) private var entitlementClient
    @Dependency(\.purchaseClient) private var purchaseClient

    @State private var entitlement: Entitlement = .free
    @State private var products: [SubscriptionProduct] = []
    @State private var status: SubscriptionStatus = .free
    @State private var gates: [GateResult] = []
    @State private var message: String?
    @State private var isWorking = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    gateSection
                    productSection
                    actionSection
                    noteSection
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 620)
        .task { await reload() }
        .task {
            // 구매·복원·환불로 등급이 바뀌면 스트림이 알려준다. 화면을 열어둔 채 Transaction Manager에서 만료시켜도 여기 값이 따라 바뀌는지 확인할 수 있다.
            for await next in entitlementClient.stream() {
                entitlement = next
                await reloadGates()
            }
        }
    }
}

// MARK: - Sections

extension DebugPaywallView {

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Debug Paywall").font(.headline)
                Text("데모용입니다. 진짜 페이월(B2)이 아닙니다.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(entitlement == .pro ? "PRO" : "FREE")
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(entitlement == .pro ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(entitlement == .pro ? Color.white : Color.primary)
                .clipShape(Capsule())
            Button("닫기") { dismiss() }
        }
        .padding(16)
    }

    private var gateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("게이트 판정").font(.subheadline.bold())
            Text("구매 전후로 이 값들이 어떻게 바뀌는지 보는 것이 이 화면의 목적이다.")
                .font(.caption).foregroundStyle(.secondary)

            ForEach(gates) { gate in
                HStack {
                    Text(gate.name).font(.callout)
                    Spacer()
                    Text(gate.display)
                        .font(.callout.monospaced())
                        .foregroundStyle(gate.tint)
                }
            }

            if let renewsAt = status.renewsAt {
                Divider().padding(.vertical, 4)
                LabeledContent("갱신일", value: renewsAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("자동 갱신", value: status.willAutoRenew ? "켜짐" : "꺼짐")
            }
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("상품 (\(products.count))").font(.subheadline.bold())

            if products.isEmpty {
                Text("상품이 없다. `./scripts/generate-storekit`으로 테스트 스토어를 붙였는지 확인할 것.")
                    .font(.caption).foregroundStyle(.orange)
            }

            ForEach(products) { product in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayName).font(.callout)
                        Text(product.monthlyEquivalentPrice.map { "\(product.displayPrice) · 월 \($0)" } ?? product.displayPrice)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("구매") { Task { await purchase(product) } }
                        .disabled(isWorking)
                }
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 8) {
            Button("복원") { Task { await restore() } }
            Button("등급 다시 읽기") { Task { await reload() } }
            Spacer()
        }
        .disabled(isWorking)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            Text("만료·환불은 Xcode의 Debug ▸ StoreKit ▸ Manage Transactions에서 조작한다. 이 화면을 열어둔 채 바꾸면 위 값이 따라 바뀐다.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Actions

extension DebugPaywallView {

    private func reload() async {
        await reloadProducts()
        await reloadGates()
        status = await purchaseClient.subscriptionStatus()
        entitlement = entitlementClient.current()
    }

    private func reloadProducts() async {
        do {
            products = try await purchaseClient.products()
        } catch {
            message = "상품 조회 실패: \(error)"
        }
    }

    private func reloadGates() async {
        let client = entitlementClient
        gates = [
            await GateResult(name: "Secret 생성", value: { try await client.canCreateSecret() }),
            await GateResult(name: "Project 생성", value: { try await client.canCreateProject() }),
            await GateResult(name: "Secret 수정", value: { try await client.canEditSecrets() }),
            GateResult(name: "iCloud 동기화", value: client.canEnableICloudSync()),
            GateResult(name: "만료 알림 다중 시점", value: client.canUseMultipleExpiryAlertDays()),
        ]
    }

    private func purchase(_ product: SubscriptionProduct) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await purchaseClient.purchase(productID: product.id)
            message = "구매 결과: \(result)"
        } catch {
            message = "구매 실패: \(error)"
        }
        await reload()
    }

    private func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await purchaseClient.restore()
            message = "복원 완료"
        } catch {
            message = "복원 실패: \(error)"
        }
        await reload()
    }
}

// MARK: - GateResult

/// 게이트 하나의 판정 결과. 판정 실패는 게이트에 걸린 것이 아니라 저장소가 깨진 것이므로 따로 표시한다.
private struct GateResult: Identifiable {
    let id = UUID()
    let name: String
    let allowed: Bool?
    let failure: String?

    init(name: String, value: Bool) {
        self.name = name
        self.allowed = value
        self.failure = nil
    }

    init(name: String, value: () async throws -> Bool) async {
        self.name = name
        do {
            self.allowed = try await value()
            self.failure = nil
        } catch {
            self.allowed = nil
            self.failure = "\(error)"
        }
    }

    var display: String {
        if let failure { return "판정 실패 — \(failure)" }
        return allowed == true ? "열림" : "잠김"
    }

    var tint: Color {
        if failure != nil { return .orange }
        return allowed == true ? .green : .secondary
    }
}
#endif
