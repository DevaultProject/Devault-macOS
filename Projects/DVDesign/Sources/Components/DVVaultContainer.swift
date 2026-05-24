// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 시스템 `List(selection:)` 안에 행으로 넣어 사용한다.
/// 선택 표시는 List(.sidebar) + `.tint(...)`에 위임, 컨텍스트 메뉴는 호출부에서 `.contextMenu`로 부착.
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
    public let isSelected: Bool

    // MARK: - Init

    public init(
        name: String,
        date: String,
        trailingIcon: TrailingIcon? = nil,
        isSelected: Bool = false
    ) {
        self.name = name
        self.date = date
        self.trailingIcon = trailingIcon
        self.isSelected = isSelected
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 14) {
            avatarCircle
            textStack
            Spacer(minLength: 8)
            trailingIconView
        }
        .padding(8)
        .frame(minWidth: 200, alignment: .leading)
    }
}

// MARK: - Subviews

extension DVVaultContainer {

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
                .truncationMode(.tail)
            Text(date)
                .dvFont(.captionMDRegular)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(minWidth: 60, alignment: .leading)
    }

    @ViewBuilder
    private var trailingIconView: some View {
        if let trailingIcon {
            Image(systemName: trailingIcon.iconName)
                .foregroundStyle(isSelected ? Color.dv(.white) : trailingIcon.iconColor)
                .fixedSize()
        }
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
