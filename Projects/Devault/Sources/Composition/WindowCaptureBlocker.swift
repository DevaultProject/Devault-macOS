// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 설정(화면 녹화 중 값 숨김)에 따라 앱 창을 스크린샷·화면 녹화·화면 공유 대상에서 제외한다.
/// `NSWindow.sharingType = .none`은 창 전체가 캡처 대상에서 빠짐
struct WindowCaptureBlocker: NSViewRepresentable {
  private let isEnabled: Bool

  init(isEnabled: Bool) {
    self.isEnabled = isEnabled
  }

  func makeNSView(context: Context) -> NSView {
    CaptureBlockingView(isEnabled: isEnabled)
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    (nsView as? CaptureBlockingView)?.update(isEnabled: isEnabled)
  }
}

/// `makeNSView` 시점엔 view가 아직 window 계층에 붙기 전이라 window가 nil이므로,
/// AppKit이 제공하는 "view가 실제로 window에 붙는 순간" 콜백을 써서 틈을 없앤다.
private final class CaptureBlockingView: NSView {
  private var isEnabled: Bool

  init(isEnabled: Bool) {
    self.isEnabled = isEnabled
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    applySharingType()
  }

  func update(isEnabled: Bool) {
    self.isEnabled = isEnabled
    applySharingType()
  }

  func applySharingType() {
    window?.sharingType = isEnabled ? .none : .readOnly
  }
}
