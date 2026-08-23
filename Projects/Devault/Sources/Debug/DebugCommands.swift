// Copyright © 2026 Devault. All rights reserved

#if DEBUG
import SwiftUI

/// DEBUG 빌드에만 붙는 Debug 메뉴.
///
/// `AppCommands`(DVPresentation)를 건드리지 않고 앱 타겟에 따로 둔다 — 데모용 도구라 제품 메뉴 카탈로그에 섞이면 안 된다.
struct DebugCommands: Commands {

    @Binding var isPaywallPresented: Bool

    var body: some Commands {
        CommandMenu("Debug") {
            Button("Paywall (데모)…") { isPaywallPresented = true }
                .keyboardShortcut("p", modifiers: [.option, .command])
        }
    }
}
#endif
