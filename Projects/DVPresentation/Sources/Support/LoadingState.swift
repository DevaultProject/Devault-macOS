// Copyright © 2026 Devault. All rights reserved

// MARK: - LoadingState

/// "아직 로드되지 않음"과 "로드했지만 결과가 비어 있음"을 구분하기 위한 상태.
/// TCA_GUIDELINES 2.4절 — 화면이 로딩 스피너 / 빈 상태 / 결과 / 에러 네 가지 모습을 모두 가져야 할 때 사용한다.
enum LoadingState<Value: Equatable, Failure: Equatable>: Equatable {
  case idle
  case loading
  case loaded(Value)
  case failed(Failure)
}
