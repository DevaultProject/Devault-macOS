// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// Devault 디자인 시스템 스타일의 단일 라디오 버튼.
///
/// `DVRadioButton`은 상호배타적 선택지(mutually-exclusive set) 중 하나의
/// 옵션을 표현합니다. 16×16 원형 인디케이터와 라벨을 가로로 배치하고,
/// 사용자 활성화 이벤트는 `action` 클로저로 전달합니다. 컴포넌트 자체는
/// **상태를 보유하지 않으며(stateless)**, `isSelected` 값과 그에 따른
/// 갱신 책임은 호출 측에 있습니다.
///
/// ## 시각 상태
///
/// | 상태 | 인디케이터 |
/// |------|-----------|
/// | 기본 (`isSelected == false`) | ``DVColor/gray300`` 으로 채워진 16pt 원 |
/// | 선택 (`isSelected == true`) | ``DVColor/vaultGreen`` 으로 채워진 16pt 원 + 가운데 5pt 흰색 점 |
///
/// 모든 색상은 ``DVColor`` 토큰을 통해 해석되므로, 에셋 카탈로그에
/// 라이트/다크 변형이 정의되면 자동으로 적응합니다.
///
/// ## 인터랙션 (macOS)
///
/// - **마우스**: 패딩된 HStack 영역 — 인디케이터, 3pt 갭, 라벨 텍스트,
///   2/4pt 외곽 패딩 — 어디를 클릭해도 `action`이 호출됩니다. 시각 인디케이터는
///   16pt 원을 유지하면서 hit target은 세로 24pt로 확대되어 macOS 권장
///   클릭 영역을 충족합니다.
/// - **키보드**: focusable 이므로 Tab으로 포커스할 수 있고, Space로
///   활성화됩니다. 시스템 기본 포커스 링은 `focusEffectDisabled()`로
///   숨기며, 선택 여부는 인디케이터의 색 변화로만 표현하는 것이 의도된
///   디자인입니다.
/// - **호버**: 호버 효과를 적용하지 않습니다 — native `NSButton` 라디오
///   컨트롤의 외관과 일치합니다.
/// - **VoiceOver**: `.isButton` 트레이트를 가지며, `isSelected == true`일
///   때 `.isSelected` 트레이트가 추가됩니다.
///
/// ## 그룹으로 묶기
///
/// 여러 옵션 간 상호배타 선택이 필요할 때는 개별 `DVRadioButton`을 손수
/// 연결하기보다 ``DVRadioButtonGroup``을 사용하세요. 그룹은 화살표 키
/// 네비게이션과 디자인 토큰 기반 간격을 함께 제공합니다.
///
/// ```swift
/// DVRadioButton("Dev", isSelected: env == .dev) {
///     env = .dev
/// }
/// ```
///
/// ## 커스텀 라벨
///
/// 단순 텍스트 이상의 라벨(아이콘, 다중 줄, 다른 타이포그래피 등)이
/// 필요할 때는 후행 클로저 이니셜라이저를 사용합니다.
///
/// ```swift
/// DVRadioButton(isSelected: agreed, action: { agreed.toggle() }) {
///     HStack(spacing: 4) {
///         Image(systemName: "checkmark.seal")
///         Text("동의합니다")
///     }
/// }
/// ```
/// ## 읽기 전용 모드
///
/// 선택 상태를 **표시만** 하고 값 변경을 허용하지 않아야 하는 화면(예: 시크릿 조회)에서는
/// ``init(readOnly:isSelected:)`` 또는 `isInteractive: false`를 사용합니다. 이 모드에서는
/// 탭 제스처·포커스·Space 키 핸들러가 **뷰 트리에 아예 부착되지 않으며**, 접근성
/// 트레이트도 `.isButton`을 갖지 않습니다.
///
/// `.disabled(true)`와 다른 점: `.disabled`는 컨트롤을 "비활성" 외관으로 바꾸지만
/// 여기서는 **선택 상태의 색 표현을 그대로 유지**한 채 인터랙션만 제거합니다 —
/// 조회 화면에서 선택된 서브타입이 흐리게 보이면 안 되기 때문입니다.
public struct DVRadioButton<Label: View>: View {
    private let isSelected: Bool
    private let isInteractive: Bool
    private let action: () -> Void
    private let label: () -> Label

    /// 임의의 라벨 뷰를 갖는 라디오 버튼을 생성합니다.
    ///
    /// 라벨이 단순 텍스트 `String`이라면 ``init(_:isSelected:action:)``을
    /// 사용하는 편이 좋습니다 — 디자인 시스템 타이포그래피가 자동으로
    /// 적용됩니다. 아이콘, 서식 있는 텍스트, 혼합 콘텐츠 등 커스텀 라벨이
    /// 필요한 경우에 이 이니셜라이저를 사용하세요.
    ///
    /// - Parameters:
    ///   - isSelected: 현재 선택 여부. 인디케이터의 색과 `.isSelected`
    ///     접근성 트레이트를 결정합니다.
    ///   - isInteractive: `false`면 탭·포커스·Space 핸들러를 부착하지 않아
    ///     값 변경이 불가능해집니다. 기본 `true`.
    ///   - action: 클릭/탭 또는 포커스 상태에서 **Space** 키를 누를 때
    ///     호출되는 클로저. 호출자가 `isSelected`의 원천 값을 직접
    ///     갱신해야 합니다. `isInteractive == false`면 호출되지 않습니다.
    ///   - label: 인디케이터 우측에 3pt 간격으로 렌더링될 라벨을 만드는
    ///     뷰 빌더.
    public init(
        isSelected: Bool,
        isInteractive: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isSelected = isSelected
        self.isInteractive = isInteractive
        self.action = action
        self.label = label
    }

    public var body: some View {
        if isInteractive {
            labelRow
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
                .focusable(true)
                .focusEffectDisabled()
                .onKeyPress(.space) {
                    action()
                    return .handled
                }
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        } else {
            labelRow
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }

    private var labelRow: some View {
        HStack(spacing: 3) {
            indicator
            label()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private var indicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.dv(.vaultGreen) : Color.dv(.gray300))
                .frame(width: 16, height: 16)
            if isSelected {
                Circle()
                    .fill(Color.dv(.white))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

extension DVRadioButton where Label == Text {
    /// 디자인 시스템 타이포그래피가 적용된 단순 텍스트 라벨 라디오 버튼을
    /// 생성합니다.
    ///
    /// 라벨은 ``DVFont/bodyMD`` (SF Pro 13pt medium)와 ``DVColor/gray900``으로
    /// 렌더링됩니다. 일반 제품 UI에서 가장 흔하게 쓰이는 형태이며, 텍스트가
    /// 아닌 콘텐츠가 필요할 때만 ``init(isSelected:action:label:)``을 사용하세요.
    ///
    /// ```swift
    /// DVRadioButton("Staging", isSelected: env == .staging) {
    ///     env = .staging
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: 인디케이터 옆에 표시될 텍스트.
    ///   - isSelected: 선택 상태 — ``init(isSelected:action:label:)`` 참고.
    ///   - action: 활성화 핸들러 — ``init(isSelected:action:label:)`` 참고.
    public init(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.init(isSelected: isSelected, action: action) {
            Text(title)
                .font(DVFont.bodyMD.font)
                .foregroundStyle(Color.dv(.gray900))
        }
    }

    /// 선택 상태를 표시만 하는 **읽기 전용** 텍스트 라디오 버튼을 생성합니다.
    ///
    /// 값 변경 액션이 아예 없으므로 조회 전용 화면에서 실수로 인터랙션이 붙는 것을
    /// 컴파일 타임에 방지합니다. 선택 상태의 색 표현은 인터랙티브 모드와 동일합니다 —
    /// `.disabled(true)`처럼 흐려지지 않습니다.
    ///
    /// ```swift
    /// DVRadioButton(readOnly: "Access Token", isSelected: true)
    /// ```
    ///
    /// - Parameters:
    ///   - title: 인디케이터 옆에 ``DVFont/bodyMD``로 표시될 텍스트.
    ///   - isSelected: 선택 상태. 인디케이터 색만 결정하며 사용자가 바꿀 수 없습니다.
    public init(
        readOnly title: String,
        isSelected: Bool
    ) {
        self.init(isSelected: isSelected, isInteractive: false, action: {}) {
            Text(title)
                .font(DVFont.bodyMD.font)
                .foregroundStyle(Color.dv(.gray900))
        }
    }
}

#Preview("Default") {
    DVRadioButton("Dev", isSelected: false, action: {})
        .padding()
}

#Preview("Selected") {
    DVRadioButton("Dev", isSelected: true, action: {})
        .padding()
}

#Preview("Interactive") {
    DVRadioButtonInteractivePreview()
        .padding()
}

#Preview("Read-only (탭·포커스·Space 모두 무반응)") {
    VStack(alignment: .leading, spacing: 12) {
        DVRadioButton(readOnly: "API Key", isSelected: false)
        DVRadioButton(readOnly: "Access Token", isSelected: true)
        DVRadioButton(readOnly: "API Webhook Secret", isSelected: false)
    }
    .padding()
}

private struct DVRadioButtonInteractivePreview: View {
    @State private var isSelected = false

    var body: some View {
        DVRadioButton("Tap me", isSelected: isSelected) {
            isSelected.toggle()
        }
    }
}
