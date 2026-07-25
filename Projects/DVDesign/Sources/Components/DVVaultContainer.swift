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
    public let service: String?
    /// `service`가 비어 있을 때만 쓰이는 최종 폴백. 호출부가 자신의 타입 분류에 맞는 SF Symbol 등을 넘긴다.
    public let typeIcon: Image?
    public let trailingIcon: TrailingIcon?
    public let isSelected: Bool

    // MARK: - Init

    public init(
        name: String,
        date: String,
        service: String? = nil,
        typeIcon: Image? = nil,
        trailingIcon: TrailingIcon? = nil,
        isSelected: Bool = false
    ) {
        self.name = name
        self.date = date
        self.service = service
        self.typeIcon = typeIcon
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

    @ViewBuilder
    private var avatarCircle: some View {
        if let logo = ServiceLogoCatalog.logo(forService: service) {
            Circle()
                .fill(logo.brandColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(logo.assetName, bundle: .module)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Color.dv(.white))
                )
        } else if let serviceInitial {
            Circle()
                .fill(Color.dv(.gray300))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(serviceInitial)
                        .dvFont(.headingLG)
                        .foregroundStyle(Color.dv(.gray600))
                )
        } else {
            Circle()
                .fill(Color.dv(.gray300))
                .frame(width: 44, height: 44)
                .overlay {
                    if let typeIcon {
                        typeIcon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.dv(.gray600))
                    }
                }
        }
    }

    /// 로고 매칭에 실패했지만 `service` 자체는 채워져 있을 때 쓰는 중간 폴백.
    private var serviceInitial: String? {
        guard let service else { return nil }
        guard let first = service.trimmingCharacters(in: .whitespacesAndNewlines).first else { return nil }
        return String(first).uppercased()
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray900))
                .lineLimit(1)
                .truncationMode(.tail)
            Text(date)
                .dvFont(.captionMDRegular)
                .foregroundStyle(Color.dv(.gray600))
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
