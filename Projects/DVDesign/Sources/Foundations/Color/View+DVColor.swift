// Copyright © 2026 Devault. All rights reserved

import SwiftUI

extension View {
    public func dvForegroundColor(_ token: DVColor) -> some View {
        self.foregroundStyle(token.color)
    }

    public func dvBackgroundColor(_ token: DVColor) -> some View {
        self.background(token.color)
    }

    public func dvScreenBackground(_ token: DVColor = .gray100) -> some View {
        self.background(token.color.ignoresSafeArea())
    }
}
