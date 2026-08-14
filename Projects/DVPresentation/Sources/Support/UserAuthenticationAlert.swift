// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain

/// Touch ID/시스템 암호 인증 실패를 안내하는 alert.
func makeUserAuthenticationFailedAlert<Alert>(
  title: String,
  error: UserAuthenticationError
) -> AlertState<Alert> {
  let message: String
  switch error {
  case .unavailable:
    message = String.module("Check that a login password is set in System Settings.")
  case .cancelled:
    message = String.module("Please try again.")
  case .failed:
    message = String.module("Please try again.")
  }
  return AlertState {
    TextState(title)
  } actions: {
    ButtonState(role: .cancel) { TextState(String.module("OK")) }
  } message: {
    TextState(message)
  }
}
