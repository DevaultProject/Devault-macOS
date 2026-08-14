// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVPresentation

/// 설정(화면 녹화 중 값 숨김)에 따라 앱 창을 스크린샷·화면 녹화·화면 공유 대상에서 제외한다.
/// `NSWindow.sharingType = .none`은 창 전체가 캡처 대상에서 빠짐
struct WindowCaptureBlocker: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    CaptureBlockingView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    (nsView as? CaptureBlockingView)?.applySharingType()
  }
}

/// `makeNSView` 시점엔 view가 아직 window 계층에 붙기 전이라 window가 nil이므로,
/// AppKit이 제공하는 "view가 실제로 window에 붙는 순간" 콜백을 써서 틈을 없앤다.
///
/// 설정 변경은 SwiftUI 뷰 트리 재평가와 무관하게(Settings 화면이 이 뷰의 상위 계층이 아니므로)
/// 반영돼야 하므로, `updateNSView` 대신 `UserDefaults.didChangeNotification`을 직접 구독한다.
private final class CaptureBlockingView: NSView {
  @Dependency(\.settingsClient) private var settingsClient
  private var observer: NSObjectProtocol?

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    applySharingType()
    if window != nil, observer == nil {
      observer = NotificationCenter.default.addObserver(
        forName: UserDefaults.didChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.applySharingType()
      }
    }
  }

  func applySharingType() {
    window?.sharingType = settingsClient.isHideDuringScreenRecordingEnabled() ? .none : .readOnly
  }

  deinit {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}
