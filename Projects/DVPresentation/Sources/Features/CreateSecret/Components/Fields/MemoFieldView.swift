// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 폼의 Memo 필드 (모든 secretType 공통, optional).
/// `SecretMetaFields.memo`에 바인딩하며, 생성 화면과 수정 화면이 `FormSectionScaffold`를 통해
/// 이 필드 하나를 공유한다.
///
/// 여러 줄 입력이다. 메모는 본질적으로 자유 서술이라 한 줄에 담기지 않는 경우가 흔한데,
/// 단일 라인으로 두면 긴 메모가 가로로만 흐르고 앞부분이 잘려 **이미 적어둔 내용을 확인하며
/// 고칠 수가 없다.** 조회 화면은 `DVTextContainer`가 개행을 그대로 그리므로 별도 대응이 필요 없다.
struct MemoFieldView: View {

    @Binding var memo: String

    var body: some View {
        LabeledTextFieldView(
            label: .module("Memo"),
            placeholder: .module("optional"),
            text: $memo,
            isMultiline: true,
            sizeMode: .fullWidth
        )
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Empty · Dual") {
    MemoFieldPreview()
        .padding()
        .formLayout(.dual)
        .previewWidth(.wide)
}

#Preview("Filled · Single") {
    MemoFieldPreview(initial: "Rotate quarterly")
        .padding()
        .formLayout(.single)
        .previewWidth(.narrow)
}

/// 개행이 든 값. 높이가 고정이라 넘치는 줄은 스크롤로 넘어가는지 함께 본다.
#Preview("Multiline · Dual") {
    MemoFieldPreview(
        initial: """
        분기마다 교체한다
        교체 후 #infra 채널에 공유
        만료 알림은 30일 전부터
        """
    )
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

private struct MemoFieldPreview: View {
    @State private var memo: String

    init(initial: String = "") {
        _memo = State(initialValue: initial)
    }

    var body: some View {
        MemoFieldView(memo: $memo)
    }
}

#endif
