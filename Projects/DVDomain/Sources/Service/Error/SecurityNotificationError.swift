// Copyright © 2026 Devault. All rights reserved

public enum SecurityNotificationError: Error, Equatable, Sendable {
    case authorizationRequestFailed
    case deliveryFailed
    case scheduleFailed
}
