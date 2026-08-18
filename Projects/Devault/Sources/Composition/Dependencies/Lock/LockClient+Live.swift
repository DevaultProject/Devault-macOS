// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation

extension LockClient: @retroactive DependencyKey {
  public static let liveValue: LockClient = {
    LockClient(
      unlock: {
        try await LiveUseCases.authenticate.authenticate(reason: "잠금을 해제하려면 인증이 필요합니다")
      }
    )
  }()
}
