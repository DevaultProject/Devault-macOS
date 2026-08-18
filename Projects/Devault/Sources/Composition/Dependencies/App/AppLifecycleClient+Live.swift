// Copyright © 2026 Devault. All rights reserved

import AppKit
import ComposableArchitecture
import DVPresentation

extension AppLifecycleClient: @retroactive DependencyKey {

    public static let liveValue = AppLifecycleClient(
        events: {
            AsyncStream { continuation in
                // macOS에는 iOS의 background 개념이 없다. 다른 앱으로 전환되어 활성 상태를
                // 잃는 순간이 "화면을 떠났다"에 해당하므로 이 알림을 쓴다.
                let observer = NotificationCenter.default.addObserver(
                    forName: NSApplication.didResignActiveNotification,
                    object: nil,
                    queue: nil
                ) { _ in
                    continuation.yield(.didEnterBackground)
                }

                continuation.onTermination = { _ in
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    )
}
