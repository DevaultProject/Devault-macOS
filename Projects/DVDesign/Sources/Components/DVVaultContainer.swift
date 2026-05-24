// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVVaultContainer: View {

    // MARK: - Types

    public enum TrailingIcon {
        case expiringSoon
        case expired
    }

    // MARK: - Properties

    public let name: String
    public let date: String
    public let trailingIcon: TrailingIcon?

    @State private var isRightClicked = false

    // MARK: - Init

    public init(
        name: String,
        date: String,
        trailingIcon: TrailingIcon? = nil
    ) {
        self.name = name
        self.date = date
        self.trailingIcon = trailingIcon
    }

    // MARK: - Body

    public var body: some View {
        rowContent
            .background(RightClickDetector(onRightClick: { isRightClicked = true },
                                           onReset: { isRightClicked = false }))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(borderOverlay)
    }
}

// MARK: - Subviews

extension DVVaultContainer {

    private var rowContent: some View {
        HStack(spacing: 14) {
            avatarCircle
            textStack
            Spacer()
            trailingIconView
        }
        .padding(8)
    }

    private var avatarCircle: some View {
        Circle()
            .fill(Color.dv(.gray300))
            .frame(width: 44, height: 44)
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .dvFont(.bodyLG)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(date)
                .dvFont(.captionMDRegular)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var trailingIconView: some View {
        if let trailingIcon {
            Image(systemName: trailingIcon.iconName)
                .foregroundStyle(trailingIcon.iconColor)
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isRightClicked ? Color.dv(.vaultGreen) : Color.clear, lineWidth: 1)
    }
}

// MARK: - TrailingIcon Appearance

extension DVVaultContainer.TrailingIcon {

    fileprivate var iconName: String {
        switch self {
        case .expiringSoon: return "clock"
        case .expired:      return "exclamationmark.circle"
        }
    }

    fileprivate var iconColor: Color {
        switch self {
        case .expiringSoon: return Color.dv(.warning)
        case .expired:      return Color.dv(.danger)
        }
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
