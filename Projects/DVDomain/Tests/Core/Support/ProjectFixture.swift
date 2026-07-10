// Copyright © 2026 Devault. All rights reserved

import Foundation

@testable import DVDomain

/// Project 관련 테스트 fixture 팩토리.
public enum ProjectFixture {
    public static let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    public static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    public static func make(
        id: UUID = fixedID,
        name: String = "Test Project",
        createdAt: Date = fixedDate,
        updatedAt: Date = fixedDate
    ) -> Project {
        Project(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
