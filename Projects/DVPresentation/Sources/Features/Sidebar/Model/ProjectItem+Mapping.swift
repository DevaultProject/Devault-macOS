// Copyright © 2026 Devault. All rights reserved

import DVDomain

extension ProjectItem {
  public init(_ project: Project) {
    self.init(id: project.id, name: project.name)
  }
}
