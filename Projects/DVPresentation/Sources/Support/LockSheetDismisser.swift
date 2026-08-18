// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

/// 잠금으로 전환될 때 창에 붙어 있는 시트·알럿을 강제로 닫는다.
///
/// SwiftUI에서 `.sheet`/`.alert`를 띄운 뷰(메인)가 잠금 화면으로 교체돼 사라지면, AppKit은 그
/// 시트 창을 dismiss하지 못하고 잠금 위에 **고아**로 남긴다(presenter가 사라지면 바인딩이 nil로
/// 관찰되지 못한다). 여기서 창에 직접 `endSheet`를 보내 닫는다.
///
/// 창 크롬(NavigationSplitView 사이드바 토글 등)은 메인이 사라지며 함께 없어지므로 대상이 아니다.
struct LockSheetDismisser: NSViewRepresentable {
  let isLocked: Bool

  func makeNSView(context: Context) -> NSView { NSView() }

  func updateNSView(_ nsView: NSView, context: Context) {
    let becameLocked = isLocked && !context.coordinator.wasLocked
    context.coordinator.wasLocked = isLocked
    guard becameLocked else { return }

    // 잠금 상태 반영으로 메인(=presenter)이 사라진 뒤의 창 상태를 봐야 하므로 다음 런루프로 미룬다.
    DispatchQueue.main.async {
      guard let sheet = nsView.window?.attachedSheet else { return }
      nsView.window?.endSheet(sheet)
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  final class Coordinator {
    var wasLocked = false
  }
}
