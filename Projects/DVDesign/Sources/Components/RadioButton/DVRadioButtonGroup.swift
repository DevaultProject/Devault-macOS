// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 상호배타적으로 선택되는 ``DVRadioButton`` 옵션들을 가로로 배열한 그룹.
///
/// `DVRadioButtonGroup`은 하나의 선택 값을 `Binding`으로 받아 ``Item``마다
/// 한 개의 ``DVRadioButton``을 렌더링하고, 선택된 ``Size`` 변형에 따라
/// 간격과 최소 너비를 적용합니다. 사용자가 클릭, 탭, 또는 키보드로 어떤
/// 라디오를 활성화하면 그 값이 바인딩에 기록됩니다.
///
/// ## 선택 바인딩
///
/// `Value`는 `Hashable`을 만족하는 어떤 타입이든 될 수 있습니다 — 문자열
/// 식별자, enum 케이스, 숫자 id 등. 그룹은 `id`가 `selection`과 일치하는
/// 라디오를 선택된 상태로 표시합니다. 호출자는 `@State`, `@AppStorage`,
/// 또는 뷰모델 `Binding`을 통해 원천 데이터를 소유합니다.
///
/// ```swift
/// enum Env: Hashable { case dev, staging, prod }
///
/// struct EnvironmentPicker: View {
///     @State private var env: Env = .dev
///
///     var body: some View {
///         DVRadioButtonGroup(
///             items: [
///                 .init(.dev, title: "Dev"),
///                 .init(.staging, title: "Staging"),
///                 .init(.prod, title: "Prod"),
///             ],
///             selection: $env,
///             size: .sm
///         )
///     }
/// }
/// ```
///
/// `selection`이 `items`에 없는 값으로 설정되면 어떤 라디오도 선택된
/// 상태로 보이지 않습니다 — 의도적인 중간 상태로 쓸 수도 있지만 보통은
/// 바인딩 구성이 잘못된 경우입니다.
///
/// ## 사이즈
///
/// 주변 레이아웃의 시각적 리듬에 맞춰 변형을 선택하세요.
///
/// - ``Size/xs`` — 좁은 밀도 (간격 8pt, 최소 너비 180pt)
/// - ``Size/sm`` — 기본 (간격 20pt, 최소 너비 330pt)
/// - ``Size/md`` — 넓은 밀도 (간격 56pt, 최소 너비 380pt)
///
/// `minWidth`는 윈도우 크기가 변할 때 그룹이 디자인 footprint 아래로
/// 줄어들지 않도록 보장하는 하한선입니다.
///
/// ## 키보드 네비게이션 (macOS)
///
/// 그룹은 `NSMatrix` 라디오 컨트롤의 동작 규약을 따릅니다.
///
/// - **Tab**: 그룹의 첫 라디오로 포커스가 진입합니다. 다음 Tab은 그룹을
///   벗어나 다음 컨트롤로 이동합니다.
/// - **← / →**: 인접 라디오로 포커스와 **선택**을 함께 이동합니다.
///   양 끝에서 한 번 더 누르면 wrap되지 않고 그대로 머뭅니다.
/// - **Space**: 포커스된 라디오를 활성화합니다 (``DVRadioButton``과 동일).
///
/// 마우스 클릭은 그룹의 내부 포커스 anchor를 함께 갱신하므로, 다음에
/// 누르는 화살표 키는 클릭한 위치를 기준으로 동작합니다.
public struct DVRadioButtonGroup<Value: Hashable>: View {
    private let items: [Item]
    @Binding private var selection: Value
    private let size: Size
    @FocusState private var focusedValue: Value?

    /// 라디오 그룹을 생성합니다.
    ///
    /// - Parameters:
    ///   - items: 가로 순서로 렌더링될 옵션 배열. 각 ``Item``은 `selection`과
    ///     비교될 `Value`와 화면에 표시될 `title`을 갖습니다. 같은 그룹 안의
    ///     `Value`는 중복되어선 안 됩니다.
    ///   - selection: 현재 선택된 값에 대한 양방향 바인딩. 사용자가 어떤
    ///     라디오를 활성화하면 그룹이 이 바인딩에 쓰기를 수행합니다.
    ///   - size: 간격과 최소 너비 변형. 기본값은 ``Size/sm``.
    public init(
        items: [Item],
        selection: Binding<Value>,
        size: Size = .sm
    ) {
        self.items = items
        self._selection = selection
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(items) { item in
                DVRadioButton(item.title, isSelected: selection == item.id) {
                    selection = item.id
                    focusedValue = item.id
                }
                .focused($focusedValue, equals: item.id)
            }
        }
        .frame(minWidth: size.minWidth, alignment: .leading)
        .onKeyPress(.leftArrow) { moveSelection(by: -1) }
        .onKeyPress(.rightArrow) { moveSelection(by: +1) }
    }

    private func moveSelection(by offset: Int) -> KeyPress.Result {
        let anchor = focusedValue ?? selection
        guard let currentIndex = items.firstIndex(where: { $0.id == anchor }) else {
            return .ignored
        }
        let nextIndex = currentIndex + offset
        guard items.indices.contains(nextIndex) else { return .handled }
        let nextId = items[nextIndex].id
        selection = nextId
        focusedValue = nextId
        return .handled
    }
}

extension DVRadioButtonGroup {
    /// ``DVRadioButtonGroup`` 안에 렌더링되는 단일 옵션.
    ///
    /// `Item`은 그룹의 `selection` 바인딩과 비교되는 `Value`와 사용자가
    /// 읽는 `title`을 묶은 값 타입입니다. `Value`가 그대로 `id`로
    /// 사용되어 `ForEach` 순회의 키가 되므로, 같은 그룹 안에서 값이
    /// 중복되지 않아야 합니다.
    ///
    /// ```swift
    /// DVRadioButtonGroup<String>.Item("staging", title: "Staging")
    /// ```
    public struct Item: Identifiable {
        /// 이 옵션을 식별하는 고유 값. 그룹의 `selection` 바인딩과
        /// 비교되어 선택 상태를 결정합니다.
        public let id: Value

        /// 라디오 인디케이터 우측에 표시되는 텍스트 라벨.
        public let title: String

        /// 옵션을 생성합니다.
        ///
        /// - Parameters:
        ///   - value: 이 옵션의 고유 식별값. 같은 그룹의 다른 옵션과 중복
        ///     되어선 안 됩니다.
        ///   - title: 인디케이터 옆에 ``DVFont/bodyMD`` 타이포그래피로
        ///     렌더링될 텍스트.
        public init(_ value: Value, title: String) {
            self.id = value
            self.title = title
        }
    }

    /// ``DVRadioButtonGroup``의 레이아웃 사이즈 변형.
    ///
    /// 각 케이스는 라디오 사이의 가로 간격(``spacing``)과 그룹 HStack의
    /// 최소 너비 하한선(``minWidth``)을 Devault Figma 스펙에 맞춰 함께
    /// 고정합니다.
    public enum Size {
        /// 좁은 밀도: 간격 8pt, 최소 너비 180pt.
        case xs

        /// 기본 밀도: 간격 20pt, 최소 너비 330pt.
        case sm

        /// 넓은 밀도: 간격 56pt, 최소 너비 380pt.
        case md

        /// 인접한 라디오 버튼 사이에 삽입되는 가로 간격 (포인트 단위).
        public var spacing: CGFloat {
            switch self {
            case .xs: return 8
            case .sm: return 20
            case .md: return 56
            }
        }

        /// 그룹 HStack에 적용되는 최소 너비 (포인트 단위). 윈도우 크기가
        /// 줄어들 때 그룹이 디자인 footprint 아래로 압축되지 않도록 합니다.
        public var minWidth: CGFloat {
            switch self {
            case .xs: return 180
            case .sm: return 330
            case .md: return 380
            }
        }
    }
}

#Preview("XS (spacing 8)") {
    DVRadioButtonGroupPreview(size: .xs)
        .padding(24)
}

#Preview("SM (spacing 20)") {
    DVRadioButtonGroupPreview(size: .sm)
        .padding(24)
}

#Preview("MD (spacing 56)") {
    DVRadioButtonGroupPreview(size: .md)
        .padding(24)
}

private struct DVRadioButtonGroupPreview: View {
    let size: DVRadioButtonGroup<String>.Size
    @State private var selection: String = "staging"

    var body: some View {
        DVRadioButtonGroup(
            items: [
                .init("dev", title: "Dev"),
                .init("staging", title: "Staging"),
                .init("prod", title: "Prod"),
            ],
            selection: $selection,
            size: size
        )
    }
}
