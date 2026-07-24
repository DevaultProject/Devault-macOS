// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 가로로 배치하다가 컨테이너 너비를 넘으면 다음 줄로 wrap 하는 flow layout.
///
/// 각 subview 크기를 캐시해 `sizeThatFits`/`placeSubviews` 간 중복 측정을 피하고,
/// 두 함수 모두 동일한 `arrangement(...)` 헬퍼로 배치 계산을 위임한다.
struct DVFlowLayout: Layout {

    struct Cache {
        var proposedWidth: CGFloat?
        var sizes: [CGSize] = []
    }

    let hSpacing: CGFloat
    let vSpacing: CGFloat

    init(hSpacing: CGFloat = 10, vSpacing: CGFloat = 10) {
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let maxWidth = proposal.width ?? .infinity
        let sizes = ensureSizes(for: subviews, width: maxWidth, cache: &cache)
        return arrangement(sizes: sizes, maxWidth: maxWidth).bounds
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let sizes = ensureSizes(for: subviews, width: bounds.width, cache: &cache)
        let positions = arrangement(sizes: sizes, maxWidth: bounds.width).positions
        let itemProposal = ProposedViewSize(width: bounds.width, height: nil)

        for (index, subview) in subviews.enumerated() {
            let position = positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: itemProposal
            )
        }
    }

    /// 각 subview에 컨테이너 너비를 propose 한 결과를 캐시. 동일한 width에 대한
    /// 반복 호출 시 재계산 생략.
    private func ensureSizes(
        for subviews: Subviews,
        width: CGFloat,
        cache: inout Cache
    ) -> [CGSize] {
        if cache.proposedWidth != width || cache.sizes.count != subviews.count {
            let proposal = ProposedViewSize(width: width, height: nil)
            cache.sizes = subviews.map { $0.sizeThatFits(proposal) }
            cache.proposedWidth = width
        }
        return cache.sizes
    }

    /// 한 번의 라인 브레이크 계산으로 각 subview의 상대 위치와 전체 바운딩 사이즈를 반환.
    /// `sizeThatFits`와 `placeSubviews`가 동일한 결과를 참조하도록 단일 소스로 둔다.
    private func arrangement(
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> (positions: [CGPoint], bounds: CGSize) {
        var positions: [CGPoint] = []
        positions.reserveCapacity(sizes.count)
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            if index > 0 && currentX + size.width > maxWidth {
                currentY += lineHeight + vSpacing
                currentX = 0
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX)
            if index < sizes.count - 1 {
                currentX += hSpacing
            }
        }
        return (positions, CGSize(width: totalWidth, height: currentY + lineHeight))
    }
}
