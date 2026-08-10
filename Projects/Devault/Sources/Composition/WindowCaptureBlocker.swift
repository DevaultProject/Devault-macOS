// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 앱 창을 스크린샷·화면 녹화·화면 공유 대상에서 제외한다.
///1버
/// `NSWindow.sharingType = .none`은 창 전체가 캡처 대상에서 빠짐
struct WindowCaptureBlocker: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    // 이 시점엔 view가 아직 window 계층에 붙기 전이라 window가 nil일 수 있어 다음 run loop로 미룸
    DispatchQueue.main.async {
      view.window?.sharingType = .none
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    nsView.window?.sharingType = .none
  }
}
