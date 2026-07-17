// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Chip 기반 multi-tag 표시 필드. ``DVTextField``와 ``DVChip`` 배열을
/// 묶은 composite 컴포넌트로, 컨테이너 너비를 넘으면 chip이 자동으로 wrap.
///
/// Chip 클릭 시 텍스트가 input에 세팅되며 input과 정확히 일치하는 chip만
/// 시각적으로 숨겨집니다. 다른 chip을 클릭하거나 input을 수정하면 원래 chip이
/// 다시 나타납니다.
///
/// Chip 추가/삭제는 이 컴포넌트가 하지 않고 외부에서 `chips` 배열을 관리하는
/// 방식을 전제합니다.
public struct DVChipsField: View {

    // MARK: - Properties

    private let placeholder: String
    private let chips: [String]
    @Binding private var input: String
    private let size: DVComponentSize
    private let onTap: (String) -> Void

    // MARK: - Init

    /// Chips 필드를 생성합니다.
    ///
    /// - Parameters:
    ///   - placeholder: 입력 필드가 비어 있을 때 표시할 안내 문구.
    ///   - chips: 표시할 chip 배열. 외부(예: 감지 엔진)가 관리.
    ///   - input: 현재 입력 중인 텍스트 바인딩. chip 클릭 시 이 값이 chip 텍스트로 세팅됨.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/sm`` (330pt).
    ///   - onTap: chip 클릭 시 호출되는 side effect 콜백. 기본 no-op.
    public init(
        _ placeholder: String,
        chips: [String],
        input: Binding<String>,
        size: DVComponentSize = .sm,
        onTap: @escaping (String) -> Void = { _ in }
    ) {
        self.placeholder = placeholder
        self.chips = chips
        self._input = input
        self.size = size
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DVTextField(placeholder, text: $input, size: size)

            if !visibleChips.isEmpty {
                DVChipFlow(hSpacing: 10, vSpacing: 10) {
                    ForEach(visibleChips, id: \.self) { chip in
                        DVChip(chip) { handleTapChip(chip) }
                    }
                }
                .frame(width: size.width, alignment: .leading)
            }
        }
    }

    /// input과 정확히 일치하는 chip은 편집 대상으로 간주하여 목록에서 숨김.
    /// 다른 chip을 클릭하거나 input이 바뀌면 자동으로 다시 나타남.
    private var visibleChips: [String] {
        chips.filter { $0 != input }
    }
}

// MARK: - Behavior

extension DVChipsField {

    /// Chip 클릭 시: input에 chip 텍스트를 넣음.
    /// 원본 배열은 건드리지 않고, input과 일치하는 동안 시각적으로만 숨겨짐.
    private func handleTapChip(_ chip: String) {
        input = chip
        onTap(chip)
    }
}

// MARK: - Layout

/// Chips wrapping flow layout — 가로로 배치하다가 너비를 넘으면 다음 줄로 wrap.
///
/// SwiftUI `Layout` protocol을 사용해 컨테이너 너비에 맞춰 자동으로 세로 확장.
/// macOS 13+ 필요.
private struct DVChipFlow: Layout {

    let hSpacing: CGFloat
    let vSpacing: CGFloat

    init(hSpacing: CGFloat = 10, vSpacing: CGFloat = 10) {
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let maxWidth = proposal.width ?? .infinity

        // 각 subview에 컨테이너 너비를 propose — chip이 자연 너비가
        // 초과할 경우 tail truncate 되어 항상 한 줄에 최소 하나는 들어감.
        let chipProposal = ProposedViewSize(width: maxWidth, height: nil)

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(chipProposal)
            if index > 0 && currentX + size.width > maxWidth {
                currentY += lineHeight + vSpacing
                currentX = 0
                lineHeight = 0
            }
            currentX += size.width
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX)
            if index < subviews.count - 1 {
                currentX += hSpacing
            }
        }
        return CGSize(width: totalWidth, height: currentY + lineHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let chipProposal = ProposedViewSize(width: bounds.width, height: nil)
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(chipProposal)
            if index > 0 && currentX + size.width > bounds.maxX {
                currentY += lineHeight + vSpacing
                currentX = bounds.minX
                lineHeight = 0
            }
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: chipProposal
            )
            currentX += size.width + hSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Previews

#Preview("Empty") {
    DVChipsFieldEmptyPreview()
        .padding()
}

#Preview("With chips (wrapping)") {
    DVChipsFieldWithChipsPreview()
        .padding()
}

#Preview("Sizes") {
    DVChipsFieldSizesPreview()
        .padding()
}

private struct DVChipsFieldEmptyPreview: View {
    @State private var chips: [String] = []
    @State private var input = ""
    var body: some View {
        DVChipsField("e.g GitHub", chips: chips, input: $input, size: .sm)
    }
}

private struct DVChipsFieldWithChipsPreview: View {
    @State private var chips: [String] = [
        "GitHub", "OpenAI", "Anthropic", "AWS", "Slack", "Notion", "Linear", "LongLongName"
    ]
    @State private var input = ""
    var body: some View {
        DVChipsField("추가 서비스 입력", chips: chips, input: $input, size: .sm)
    }
}

private struct DVChipsFieldSizesPreview: View {
    @State private var xs: [String] = ["A", "B"]
    @State private var sm: [String] = ["GitHub", "OpenAI"]
    @State private var md: [String] = ["Stripe", "Vercel", "Supabase"]
    @State private var lg: [String] = ["GitHub", "OpenAI", "Anthropic", "AWS", "Slack"]
    @State private var xsInput = ""
    @State private var smInput = ""
    @State private var mdInput = ""
    @State private var lgInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DVChipsField("XS", chips: xs, input: $xsInput, size: .xs)
            DVChipsField("SM", chips: sm, input: $smInput, size: .sm)
            DVChipsField("MD", chips: md, input: $mdInput, size: .md)
            DVChipsField("LG", chips: lg, input: $lgInput, size: .lg)
        }
    }
}
