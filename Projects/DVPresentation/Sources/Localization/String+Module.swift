// Copyright © 2026 Devault. All rights reserved

import Foundation

extension String {
    /// DVPresentation 모듈 번들의 `Localizable.xcstrings` 룩업 후 `String`으로 반환.
    /// SwiftUI `Text` 자동 로컬라이즈가 안 되는 지점(파라미터가 `String` 타입인 서브뷰 등)에서
    /// `label: .module("Foo")` 형태로 축약 호출.
    static func module(_ key: String.LocalizationValue) -> String {
        String(localized: LocalizedStringResource.module(key))
    }
}
