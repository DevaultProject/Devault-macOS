// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVPresentation

extension ClipboardClient: @retroactive DependencyKey {
  public static let liveValue: ClipboardClient = ClipboardClient(
    copy: { value in
      try await LiveUseCases.copySensitiveValue.execute(value)
    }
  )
}
