// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public enum DVImage: CaseIterable {
    case appIcon

    public var image: Image {
        switch self {
        case .appIcon: return Image("appIcon", bundle: .module)
        }
    }
}
