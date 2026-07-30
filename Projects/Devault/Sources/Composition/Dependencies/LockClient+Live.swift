// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVPresentation
import DVDomain
import DVData

extension LockClient: @retroactive DependencyKey {
  public static let liveValue: LockClient = {
    let authenticationService: any UserAuthenticationService = LocalUserAuthenticationServiceImpl()

    return LockClient(
      unlock: {
        try await authenticationService.authenticate(reason: "잠금을 해제하려면 인증이 필요합니다")
      }
    )
  }()
}
