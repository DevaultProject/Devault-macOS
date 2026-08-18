// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 설정(화면 녹화 중 값 숨김)에 따라 앱 창을 스크린샷·화면 녹화·화면 공유 대상에서 제외한다.
/// `NSWindow.sharingType = .none`이면 창 전체가 캡처 대상에서 빠진다.
///
/// **Debug 빌드에서는 설정과 무관하게 막지 않는다.** 개발 중에는 화면을 찍어 PR·디자인 리뷰에
/// 붙이고 버그를 녹화해 공유해야 하는데, 캡처가 막혀 있으면 그 자리에서 검은 화면만 남는다.
/// 분기가 `#if DEBUG` 컴파일 타임이라 **Release 바이너리에는 해제 경로 자체가 들어가지 않는다** —
/// 런타임 플래그로 두면 배포본에서 뒤집힐 여지가 생기므로 그렇게 하지 않는다.
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
    applyCapturePolicy()
  }

  func update(isEnabled: Bool) {
    self.isEnabled = isEnabled
    applyCapturePolicy()
  }

  private func applyCapturePolicy() {
    window?.applyCapturePolicy(isEnabled: isEnabled)
  }
}

private extension NSWindow {

  /// 캡처 차단 여부를 한곳에서 정한다. 적용 지점이 둘(붙는 순간 · 설정 변경 시점)이라
  /// 각자 분기하면 한쪽만 고쳐져 설정과 화면이 어긋나는 상태가 생긴다.
  func applyCapturePolicy(isEnabled: Bool) {
    #if DEBUG
    // 개발 빌드는 설정을 보지 않는다. 스크린샷·녹화·화면 공유에 정상적으로 잡힌다.
    sharingType = .readOnly
    #else
    sharingType = isEnabled ? .none : .readOnly
    #endif
  }
}
