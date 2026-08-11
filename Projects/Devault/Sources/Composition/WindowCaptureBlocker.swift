// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 앱 창을 스크린샷·화면 녹화·화면 공유 대상에서 제외한다.
/// `NSWindow.sharingType = .none`은 창 전체가 캡처 대상에서 빠짐
struct WindowCaptureBlocker: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    CaptureBlockingView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    nsView.window?.sharingType = .none
  }
}

/// `makeNSView` 시점엔 view가 아직 window 계층에 붙기 전이라 window가 nil이므로,
/// AppKit이 제공하는 "view가 실제로 window에 붙는 순간" 콜백을 써서 틈을 없앤다.
private final class CaptureBlockingView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    window?.sharingType = .none
  }
}
