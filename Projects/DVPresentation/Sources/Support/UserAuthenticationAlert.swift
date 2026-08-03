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
    message = "시스템 설정에서 로그인 암호가 설정되어 있는지 확인해주세요."
  case .cancelled:
    message = "다시 시도해주세요."
  case .failed:
    message = "다시 시도해주세요."
  }
  return AlertState {
    TextState(title)
  } actions: {
    ButtonState(role: .cancel) { TextState("확인") }
  } message: {
    TextState(message)
  }
}
