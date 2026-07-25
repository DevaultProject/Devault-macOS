// Copyright © 2026 Devault. All rights reserved

import DVDomain

public extension ProjectItem {
  init(_ project: Project) {
    self.init(id: project.id, name: project.name)
  }
}
