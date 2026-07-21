// Copyright © 2026 Devault. All rights reserved

import AppKit
import SwiftUI

/// `.popover`/`Menu`와 달리 화살표가 없는 floating 패널을 앵커 뷰 아래에 띄운다.
///
/// SwiftUI `.popover`는 `NSPopover` 기반이라 화살표 모양을 없앨 방법이 없다.
/// 이 모디파이어는 별도의 borderless `NSPanel`을 직접 띄워서, 화면(윈도우) 경계 밖으로도
/// 자연스럽게 나오면서 화살표 없는 카드 모양을 그대로 유지한다.
///
/// ```swift
/// someButton
///     .floatingPanel(isPresented: $isMenuPresented) {
///         menuContent
///     }
/// ```
///
/// 패널 바깥을 클릭하면 자동으로 닫힌다(`isPresented`를 `false`로 되돌림).
public extension View {
    func floatingPanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> PanelContent
    ) -> some View {
        background(
            DVFloatingPanelPresenter(isPresented: isPresented, panelContent: content)
        )
    }
}

// MARK: - DVFloatingPanelPresenter

private struct DVFloatingPanelPresenter<PanelContent: View>: NSViewRepresentable {
    @Binding var isPresented: Bool
    let panelContent: () -> PanelContent

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.anchorView = nsView
        if isPresented {
            context.coordinator.showPanel(with: panelContent())
        } else {
            context.coordinator.closePanel()
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.closePanel()
    }
}

// MARK: - Coordinator

extension DVFloatingPanelPresenter {
    @MainActor
    final class Coordinator: NSObject {
        private let isPresentedBinding: Binding<Bool>
        weak var anchorView: NSView?
        private var panel: NSPanel?
        private var eventMonitor: Any?

        init(isPresented: Binding<Bool>) {
            self.isPresentedBinding = isPresented
        }

        func showPanel(with content: PanelContent) {
            guard panel == nil, let anchorView, let window = anchorView.window else {
                return
            }

            let hostingView = NSHostingView(rootView: content)
            let size = hostingView.fittingSize
            hostingView.frame = NSRect(origin: .zero, size: size)

            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.hasShadow = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .popUpMenu
            panel.contentView = hostingView

            let anchorFrameInWindow = anchorView.convert(anchorView.bounds, to: nil)
            let anchorFrameOnScreen = window.convertToScreen(anchorFrameInWindow)
            let origin = NSPoint(
                x: anchorFrameOnScreen.minX,
                y: anchorFrameOnScreen.minY - size.height - 4
            )
            panel.setFrameOrigin(origin)

            window.addChildWindow(panel, ordered: .above)
            panel.makeKeyAndOrderFront(nil)
            self.panel = panel

            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self, let panel = self.panel else { return event }
                if event.window !== panel {
                    self.isPresentedBinding.wrappedValue = false
                }
                return event
            }
        }

        func closePanel() {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
            }
            if let panel {
                panel.parent?.removeChildWindow(panel)
                panel.close()
            }
            panel = nil
        }
    }
}
