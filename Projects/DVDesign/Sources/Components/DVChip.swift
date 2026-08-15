// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 태그/토큰 표시용 pill 컴포넌트.
///
/// 높이 24pt, ``DVColor/vaultGreenTint`` 배경. 클릭 시 ``action`` 클로저가
/// 호출되며 chip 자체는 상태를 갖지 않습니다.
public struct DVChip: View {

    // MARK: - Properties

    private let text: String
    private let action: () -> Void

    // MARK: - Init

    public init(
        _ text: String,
        action: @escaping () -> Void = {}
    ) {
        self.text = text
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray900))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 16)
                .frame(height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.dv(.vaultGreenTint))
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Chip") {
    HStack(spacing: 10) {
        DVChip("GitHub")
        DVChip("NameNameName")
        DVChip("OpenAI")
    }
    .padding()
}

#endif
