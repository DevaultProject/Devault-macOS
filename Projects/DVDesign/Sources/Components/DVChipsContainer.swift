// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 선택된 값들을 chip 그리드로 **표시만** 하는 읽기 전용 컨테이너.
///
/// ``DVMultiSelectDropdown``의 chip 트리거와 시각적으로 동일하지만 popover·포커스·탭이 전혀 없다.
/// ``DVTextField``↔``DVTextContainer``와 같은 관계로, 다중 선택 값의 read-only counterpart다.
///
/// ## 사용
///
/// ```swift
/// DVLabeledField("Project", size: .md) {
///     DVChipsContainer(["Backend", "Infra"], size: .md)
/// }
/// ```
///
/// 값이 비면 chip 없이 박스만 남는다 — ``DVTextContainer``의 Empty 상태와 같은 취급이며,
/// 이때도 높이는 다른 읽기 전용 필드와 맞도록 28pt를 유지한다.
///
/// > Note: chip은 ``DVChip``(내부적으로 `Button`)이라 그대로 두면 포커스를 받는다.
/// > 컨테이너 전체에 `allowsHitTesting(false)`를 걸어 인터랙션을 차단한다.
///
/// > Important: 레이아웃 상수(padding·spacing·corner radius)가 ``DVMultiSelectDropdown``의
/// > chip 트리거와 중복 정의되어 있다. 그쪽은 popover를 여는 탭 영역이 컨테이너 배경까지
/// > 포함해야 해서 `allowsHitTesting(false)`를 공유할 수 없어, 의도적으로 분리해 둔다.
/// > 두 컴포넌트의 chip 표현을 바꿀 때는 **양쪽을 함께** 수정해야 한다.
public struct DVChipsContainer: View {

    // MARK: - Metrics

    private enum Metrics {
        static let chipsPadding: CGFloat = 6
        static let chipsSpacing: CGFloat = 6
        static let cornerRadius: CGFloat = 6
        /// 값이 없을 때도 다른 읽기 전용 필드(``DVTextContainer`` 28pt)와 높이를 맞춘다.
        static let minHeight: CGFloat = 28
    }

    // MARK: - Properties

    private let labels: [String]
    private let size: DVComponentSize

    // MARK: - Init

    /// - Parameters:
    ///   - labels: chip으로 표시할 텍스트 목록. 빈 배열이면 박스만 표시된다.
    ///   - size: 너비 변형. 기본값 ``DVComponentSize/md``.
    public init(
        _ labels: [String],
        size: DVComponentSize = .md
    ) {
        self.labels = labels
        self.size = size
    }

    // MARK: - Body

    public var body: some View {
        DVFlowLayout(hSpacing: Metrics.chipsSpacing, vSpacing: Metrics.chipsSpacing) {
            // 라벨이 중복될 수 있으므로 값이 아니라 위치를 id로 쓴다.
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                DVChip(label)
            }
        }
        .allowsHitTesting(false)
        .padding(Metrics.chipsPadding)
        .frame(minHeight: Metrics.minHeight)
        .dvComponentWidth(size, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .fill(Color.dv(.gray300))
        }
    }
}

// MARK: - Previews

#Preview("단일") {
    DVChipsContainer(["Backend"], size: .md)
        .padding()
}

#Preview("다중 · 줄바꿈") {
    DVChipsContainer(
        ["Backend", "Infra", "Longlonglong Project Name", "Mobile"],
        size: .md
    )
    .padding()
}

#Preview("Empty") {
    DVChipsContainer([], size: .md)
        .padding()
}

#Preview("Sizes") {
    VStack(alignment: .leading, spacing: 12) {
        DVChipsContainer(["XS"], size: .xs)
        DVChipsContainer(["SM", "Second"], size: .sm)
        DVChipsContainer(["MD", "Second"], size: .md)
        DVChipsContainer(["LG", "Second"], size: .lg)
    }
    .padding()
}
