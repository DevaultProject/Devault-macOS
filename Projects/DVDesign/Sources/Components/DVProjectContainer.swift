// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 시스템 `List(selection:)` 안에 행으로 넣어 사용한다.
/// 선택 표시는 List(.sidebar) + `.tint(...)`에 위임, 컨텍스트 메뉴는 호출부에서 `.contextMenu`로 부착.
public struct DVProjectContainer: View {

    // MARK: - Properties

    public static let projectIconSystemName = "tray"

    public let name: String
    public let count: Int

    // MARK: - Init

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 4) {
            projectIcon
            nameLabel
            Spacer(minLength: 8)
            countLabel
        }
        .padding(2)
        .frame(minWidth: 120, alignment: .leading)
    }
}

// MARK: - Subviews

extension DVProjectContainer {

    private var projectIcon: some View {
        Image(systemName: DVProjectContainer.projectIconSystemName)
            .dvFont(.captionLG)
            .foregroundStyle(Color.dv(.gray900))
    }

    private var nameLabel: some View {
        Text(name)
            .dvFont(.bodyMD)
            .foregroundStyle(Color.dv(.gray900))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(minWidth: 40, alignment: .leading)
    }

    private var countLabel: some View {
        Text(count > 999 ? "999+" : "\(count)")
            .dvFont(.bodyMD)
            .foregroundStyle(Color.dv(.gray400))
            .fixedSize()
    }
}
