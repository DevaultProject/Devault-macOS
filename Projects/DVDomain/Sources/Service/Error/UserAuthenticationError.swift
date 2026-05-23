// Copyright © 2026 Devault. All rights reserved

public enum UserAuthenticationError: Error, Equatable, Sendable {
    case unavailable
    case cancelled
    case failed
}
