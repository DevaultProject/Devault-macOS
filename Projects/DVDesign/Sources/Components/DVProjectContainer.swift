// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVProjectContainer: View {

    // MARK: - Properties

    public let name: String
    public let count: Int

    @State private var isRightClicked = false

    // MARK: - Init

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }

    // MARK: - Body

    public var body: some View {
        rowContent
            .background(RightClickDetector(onRightClick: { isRightClicked = true },
                                           onReset: { isRightClicked = false }))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(borderOverlay)
            .frame(width: 228, height: 28)
    }
}

// MARK: - Subviews

extension DVProjectContainer {

    private var rowContent: some View {
        HStack(spacing: 4) {
            projectIcon
            nameLabel
            Spacer()
            countLabel
        }
        .padding(6)
    }

    private var projectIcon: some View {
        Image(systemName: "tray")
            .dvFont(.captionLG)
            .foregroundStyle(.primary)
    }

    private var nameLabel: some View {
        Text(name)
            .dvFont(.bodyMD)
            .foregroundStyle(.primary)
            .lineLimit(1)
    }

    private var countLabel: some View {
        Text("\(count)")
            .dvFont(.bodyMD)
            .foregroundStyle(.secondary)
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isRightClicked ? Color.dv(.vaultGreen) : Color.clear, lineWidth: 1)
    }
}

// MARK: - Right Click Detector

private struct RightClickDetector: NSViewRepresentable {
    let onRightClick: () -> Void
    let onReset: () -> Void

    func makeNSView(context: Context) -> _RightClickView {
        let view = _RightClickView()
        view.onRightClick = onRightClick
        view.onReset = onReset
        return view
    }

    func updateNSView(_ nsView: _RightClickView, context: Context) {
        nsView.onRightClick = onRightClick
        nsView.onReset = onReset
    }
}

private final class _RightClickView: NSView {
    var onRightClick: (() -> Void)?
    var onReset: (() -> Void)?

    private var menuObserver: Any?

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
        super.rightMouseDown(with: event)

        menuObserver = NotificationCenter.default.addObserver(
            forName: NSMenu.didEndTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetAndRemoveObserver()
        }
    }

    override func mouseDown(with event: NSEvent) {
        resetAndRemoveObserver()
        super.mouseDown(with: event)
    }

    private func resetAndRemoveObserver() {
        onReset?()
        if let observer = menuObserver {
            NotificationCenter.default.removeObserver(observer)
            menuObserver = nil
        }
    }
}
