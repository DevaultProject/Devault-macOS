// Copyright © 2026 Devault. All rights reserved

import Foundation

public struct ProjectItem: Equatable, Identifiable, Sendable {
  public let id: UUID
  public let name: String

  public init(id: UUID, name: String) {
    self.id = id
    self.name = name
  }
}

// MARK: - Preview Fixtures

extension ProjectItem {
  public static let previews: [ProjectItem] = [
    .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Backend"),
    .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Infrastructure"),
    .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Mobile"),
  ]
}
