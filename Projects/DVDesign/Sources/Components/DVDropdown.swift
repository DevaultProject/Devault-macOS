// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 읽기 전용 트리거 필드 + macOS 시스템 Menu 팝오버.
///
/// 트리거만 디자인 토큰으로 스타일링하고, 팝오버 렌더링·정렬·하이라이트·
/// 키보드 네비게이션은 시스템 `Menu`에 위임합니다. 팝오버 내용은 caller가
/// `@ViewBuilder`로 자유롭게 제공.
public struct DVDropdown<Content: View>: View {

    // MARK: - Properties

    private let text: String
    private let size: DVComponentSize
    private let content: () -> Content

    // MARK: - Init

    /// 드롭다운을 생성합니다.
    ///
    /// - Parameters:
    ///   - text: 트리거에 표시할 현재 값 또는 placeholder (예: "Select Project").
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/sm`` (330pt).
    ///   - content: 시스템 `Menu`가 표시할 항목들 (Button, Divider 등).
    public init(
        _ text: String,
        size: DVComponentSize = .sm,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.text = text
        self.size = size
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        // .menuIndicator(.hidden): 시스템 기본 chevron 숨김
        // .menuOrder(.fixed): 팝오버가 위/아래 어느 방향으로 열려도 항목 순서 유지
        //   → "Add New Project" 같은 항목이 항상 마지막에 오도록 보장
        // .buttonStyle(.plain): 시스템 기본 버튼 chrome 제거 (커스텀 label 그대로 렌더링)
        Menu {
            content()
        } label: {
            triggerLabel
        }
        .menuIndicator(.hidden)
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .fixedSize()
    }
}

// MARK: - Subviews

extension DVDropdown {

    private var triggerLabel: some View {
        HStack(spacing: 0) {
            Text(text)
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray900))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            chevron
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(width: size.width, height: 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.dv(.gray300))
        )
    }

    private var chevron: some View {
        Image(systemName: "chevron.down")
            .font(DVFont.captionMDSemibold.font)
            .foregroundStyle(Color.black.opacity(0.85))
            .frame(width: 24, height: 24)
    }
}

// MARK: - Previews

#Preview("Placeholder") {
    DVDropdownPlaceholderPreview()
        .padding()
}

#Preview("Selected") {
    DVDropdownSelectedPreview()
        .padding()
}

#Preview("Sizes") {
    DVDropdownSizesPreview()
        .padding()
}

private struct DVDropdownPlaceholderPreview: View {
    var body: some View {
        DVDropdown("Select Project", size: .sm) {
            Button("CheerLot") {}
            Button("DrinkiG") {}
            Divider()
            Button {
            } label: {
                Label("Add New Project", systemImage: "plus")
            }
        }
    }
}

private struct DVDropdownSelectedPreview: View {
    @State private var selected: String? = "DrinkiG"

    var body: some View {
        DVDropdown(selected ?? "Select Project", size: .sm) {
            Button("CheerLot")  { selected = "CheerLot" }
            Button("DrinkiG")   { selected = "DrinkiG" }
            Button("Example")   { selected = "Example" }
        }
    }
}

private struct DVDropdownSizesPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DVDropdown("XS", size: .xs) { Button("A") {} }
            DVDropdown("SM", size: .sm) { Button("A") {} }
            DVDropdown("MD", size: .md) { Button("A") {} }
            DVDropdown("LG", size: .lg) { Button("A") {} }
        }
    }
}
