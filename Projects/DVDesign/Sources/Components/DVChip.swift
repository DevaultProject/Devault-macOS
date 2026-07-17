// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템의 태그/토큰 표시용 chip.
///
/// `DVChip`는 `Services` 같은 태그 필드에서 개별 태그를 표시하는 pill 형태
/// 컴포넌트입니다. Figma의 "Push Button" (node 396:13245)에 대응합니다.
///
/// ## 시각 스펙
///
/// - 높이: 24pt 고정
/// - 배경: ``DVColor/vaultGreenTint``
/// - 라디우스: 6pt
/// - 좌우 padding: 16pt
/// - 텍스트: ``DVFont/bodyMD``, ``DVColor/gray900``
///
/// ## 인터랙션
///
/// 클릭 시 ``action`` 클로저가 호출됩니다. 호출자가 이 액션을 "제거"로
/// 해석하는 것이 가장 흔한 패턴이지만, "선택 토글" 등 다른 의미로도
/// 사용할 수 있습니다. Chip 자체에는 상태가 없으며 관리 책임은 호출자에게 있습니다.
///
/// ## 사용
///
/// ```swift
/// DVChip("GitHub") { services.removeAll { $0 == "GitHub" } }
/// ```
public struct DVChip: View {

    // MARK: - Properties

    public let text: String
    public let action: () -> Void

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
        Button(action: action) {
            Text(text)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray900))
                .lineLimit(1)
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

#Preview("Chip") {
    HStack(spacing: 10) {
        DVChip("GitHub")
        DVChip("NameNameName")
        DVChip("OpenAI")
    }
    .padding()
}
