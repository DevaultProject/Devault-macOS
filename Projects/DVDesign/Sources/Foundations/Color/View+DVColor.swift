// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public extension View {
    func dvForegroundColor(_ token: DVColor) -> some View {
        self.foregroundStyle(token.color)
    }

    func dvBackgroundColor(_ token: DVColor) -> some View {
        self.background(token.color)
    }
}
