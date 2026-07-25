// Copyright © 2026 Devault. All rights reserved

import SwiftUI

/// 프로젝트 행 인라인 리네임 컴포넌트.
/// DVProjectContainer와 동일한 leading icon + 레이아웃에서 이름 부분을 TextField로 교체한다.
public struct DVProjectRenameContainer: View {

    // MARK: - Properties

    @Binding public var text: String
    public var onSubmit: () -> Void
    public var onCancel: () -> Void

    @FocusState private var isFocused: Bool

    // MARK: - Init

    public init(
        text: Binding<String>,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._text = text
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "tray")
                .dvFont(.captionLG)
                .foregroundStyle(Color.dv(.gray900))
            TextField("", text: $text)
                .dvFont(.bodyMD)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .onExitCommand(perform: onCancel)
        }
        .padding(2)
        .frame(minWidth: 120, alignment: .leading)
        .onAppear { isFocused = true }
    }
}
