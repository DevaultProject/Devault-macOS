// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation

@DependencyClient
public struct SidebarClient: Sendable {
  public var fetchProjects: @Sendable () async throws -> [ProjectItem]
  public var createProject: @Sendable (_ name: String) async throws -> ProjectItem
  public var renameProject: @Sendable (_ id: ProjectItem.ID, _ name: String) async throws -> ProjectItem
  public var deleteProject: @Sendable (_ id: ProjectItem.ID) async throws -> Void
}

extension SidebarClient: TestDependencyKey {
  public static let testValue = SidebarClient()

  public static let previewValue = SidebarClient(
    fetchProjects: { ProjectItem.previews },
    createProject: { name in ProjectItem(id: UUID(), name: name) },
    renameProject: { id, name in ProjectItem(id: id, name: name) },
    deleteProject: { _ in }
  )
}

extension DependencyValues {
  public var sidebarClient: SidebarClient {
    get { self[SidebarClient.self] }
    set { self[SidebarClient.self] = newValue }
  }
}
