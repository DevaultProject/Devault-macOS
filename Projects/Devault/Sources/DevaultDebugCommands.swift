// Copyright © 2026 Devault. All rights reserved

#if DEBUG

import SwiftUI

import ComposableArchitecture
import DVPresentation

/// Debug 빌드에만 붙는 메뉴.
///
/// `generate-local`로 만든 워크스페이스는 ad-hoc 서명(`CODE_SIGN_IDENTITY = "-"`)이라
/// Touch ID 평가가 실패한다. 온보딩의 Touch ID 단계와 잠금 해제가 모두 인증을 요구하므로
/// 그대로면 메인 화면까지 도달할 수 없어, 인증을 건너뛰는 통로가 필요하다.
///
/// TODO: 팀 시트가 전원에게 발급되어 `generate-local`이 필요 없어지면
/// 이 파일과 `AppFeature.Action.debugSkipToMain`을 함께 제거한다. (#64)
struct DevaultDebugCommands: Commands {

  let store: StoreOf<AppFeature>

  var body: some Commands {
    CommandMenu("Debug") {
      Button("온보딩·잠금 건너뛰고 메인 진입") {
        store.send(.debugSkipToMain)
      }
      .keyboardShortcut("m", modifiers: [.command, .option])
    }
  }
}

#endif
