// Copyright © 2026 Devault. All rights reserved

import Foundation

extension LocalizedStringResource {
    /// DVPresentation 모듈 번들의 `Localizable.xcstrings`에서 문자열을 룩업.
    public static func module(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(key, bundle: .atURL(Bundle.module.bundleURL))
    }
}
