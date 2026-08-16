// Copyright © 2026 Devault. All rights reserved

import DVDesign
import SwiftUI

/// 폼 화면 하단 고정 액션 바. Cancel + 저장, 10pt 간격 고정 + 우측 정렬.
/// 생성 화면과 수정 화면이 공유한다 — 배치·간격이 같고 다른 것은 저장 버튼 라벨뿐이다.
/// TCA store에 결합하지 않고 콜백/불리언만 받아 독립 Preview 가능.
struct FooterActionsView: View {

    /// 저장 버튼 라벨. 생성은 기본값(`Create`), 수정은 `Save`를 넘긴다.
    /// `DVButton`이 `String`을 받으므로 `String.module(_:)`로 룩업한 결과를 담는다.
    var saveTitle: String = .module("Create")
    let isSaveEnabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        actions
            .padding(.top, 8)
    }
}

// MARK: - Subviews

extension FooterActionsView {

    private var actions: some View {
        HStack {
            Spacer()
            HStack(spacing: 10) {
                DVButton(titleText: .module("Cancel"), style: .secondary, action: onCancel)
                DVButton(titleText: saveTitle, style: .secondaryProminent, action: onSave)
                    .disabled(!isSaveEnabled)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Disabled · Medium") {
    FooterActionsView(isSaveEnabled: false, onCancel: {}, onSave: {})
        .previewWidth(.medium)
}

#Preview("Enabled · Medium") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.medium)
}

#Preview("Enabled · Narrow") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.narrow)
}

#Preview("Enabled · Wide") {
    FooterActionsView(isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.wide)
}

/// 수정 화면이 쓰는 라벨. 버튼 폭이 달라지므로 Cancel과의 간격이 그대로인지 확인한다.
#Preview("Save 라벨 · Medium") {
    FooterActionsView(saveTitle: .module("Save"), isSaveEnabled: true, onCancel: {}, onSave: {})
        .previewWidth(.medium)
}

#endif
