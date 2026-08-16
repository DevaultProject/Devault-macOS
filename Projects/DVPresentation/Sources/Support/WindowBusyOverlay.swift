// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign

// MARK: - WindowBusyKey

/// 진행 중인 화면이 하나라도 있는지. 여러 화면이 동시에 참이어도 하나로 합쳐진다.
private struct WindowBusyKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - View

extension View {

    /// 이 화면이 진행 중임을 **창 루트에 알린다.** 오버레이는 여기서 그리지 않는다.
    ///
    /// 진행 오버레이를 화면 일부에만 덮으면 그 경계가 그대로 드러난다. 3컬럼에서 컬럼 하나만,
    /// 또는 스크롤 영역만 어두워지면 "무언가 진행 중"이 아니라 레이아웃이 깨진 것처럼 보이고,
    /// 어두워지지 않은 영역은 여전히 눌리는 것처럼 보여 어디까지 잠겼는지도 알 수 없다.
    ///
    /// 그래서 화면은 사실만 올려보내고 덮는 일은 ``windowBusyOverlay()``를 붙인 창 루트가 한다.
    /// 화면이 자기가 창의 어느 부분인지 알 필요가 없다.
    ///
    /// 입력을 잠그는 것은 별개다 — 필요하면 `.disabled(_:)`를 함께 쓴다.
    func windowBusy(_ isBusy: Bool) -> some View {
        preference(key: WindowBusyKey.self, value: isBusy)
    }

    /// 창 루트에 **한 번만** 붙인다. 어느 화면이든 ``windowBusy(_:)``가 참이면 창 전체를 덮는다.
    func windowBusyOverlay() -> some View {
        overlayPreferenceValue(WindowBusyKey.self) { isBusy in
            if isBusy {
                ZStack {
                    Color.black.opacity(0.08)
                    ProgressView().controlSize(.regular)
                }
                // 아래로 클릭이 새지 않게 막는다. 진행 중에는 창 전체가 잠긴 것이 맞다.
                .allowsHitTesting(true)
                .ignoresSafeArea()
                // 잠갔다는 사실을 보조 기술에도 알린다. `ProgressView`만으로는 읽어 주지 않아
                // VoiceOver 사용자에게는 창이 그냥 반응하지 않는 것으로만 보인다.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String.module("In progress"))
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }
}
