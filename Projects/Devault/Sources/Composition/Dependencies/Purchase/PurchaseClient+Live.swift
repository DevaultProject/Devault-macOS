// Copyright © 2026 Devault. All rights reserved

import AppKit
import ComposableArchitecture
import DVDomain
import DVPresentation

extension PurchaseClient: @retroactive DependencyKey {
    public static let liveValue: PurchaseClient = {
        let service = LiveServices.purchase
        return PurchaseClient(
            products: { try await service.products() },
            purchase: { try await service.purchase(productID: $0) },
            restore: { try await service.restore() },
            subscriptionStatus: { await service.subscriptionStatus() },
            refreshEntitlement: { await service.refreshEntitlement() },
            openManageSubscriptions: {
                guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
                NSWorkspace.shared.open(url)
            }
        )
    }()
}
