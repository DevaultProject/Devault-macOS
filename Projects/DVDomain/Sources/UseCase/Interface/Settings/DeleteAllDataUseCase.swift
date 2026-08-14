// Copyright © 2026 Devault. All rights reserved

import Foundation

public protocol DeleteAllDataUseCase: Sendable {
    /// 재인증 후 모든 Secret(휴지통 포함)과 Project를 영구 삭제한다. 되돌릴 수 없다.
    func execute() async throws
}
