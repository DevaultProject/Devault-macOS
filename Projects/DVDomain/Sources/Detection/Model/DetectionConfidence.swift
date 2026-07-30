// Copyright © 2026 Devault. All rights reserved

import Foundation

public enum DetectionConfidence: String, Equatable, Sendable, Comparable, CaseIterable {
    case low
    case medium
    case high

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let rank: [Self: Int] = [.low: 0, .medium: 1, .high: 2]
        return rank[lhs]! < rank[rhs]!
    }
}
