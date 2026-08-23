// Copyright © 2026 Devault. All rights reserved

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
            subscriptionStatus: { await service.subscriptionStatus() }
        )
    }()
}
