// Copyright © 2026 Devault. All rights reserved

import CasePaths
import SwiftUI

extension Binding where Value: CasePathable {

    /// `Binding<CasePathable Enum>`에서 특정 case의 associated value에 대한 non-optional `Binding<T>`를 얻는 헬퍼.
    ///
    /// State가 다른 case일 때(`self.wrappedValue[case: path]`가 nil)는 `fallback`을 반환하고,
    /// set 시엔 `path(newValue)`로 대상 case를 embed. 주로 SwiftUI 서브뷰가 특정 case의
    /// 하위 필드에 바인딩해야 할 때 사용 — 상위 뷰에서 case 게이팅을 이미 했다는 전제.
    ///
    /// ```swift
    /// // Before (per-file 반복):
    /// private var apiKeyTokenBinding: Binding<APIKeyTokenFields> {
    ///     Binding(
    ///         get: {
    ///             if case .apiKeyToken(let f) = store.meta.content { return f }
    ///             return APIKeyTokenFields()
    ///         },
    ///         set: { store.meta.content = .apiKeyToken($0) }
    ///     )
    /// }
    ///
    /// // After:
    /// $store.meta.content.typed(\.apiKeyToken, default: APIKeyTokenFields())
    /// ```
    func typed<T>(
        _ path: CaseKeyPath<Value, T>,
        default fallback: @autoclosure @escaping () -> T
    ) -> Binding<T> {
        Binding<T>(
            get: { self.wrappedValue[case: path] ?? fallback() },
            set: { newValue in self.wrappedValue = path(newValue) }
        )
    }
}
