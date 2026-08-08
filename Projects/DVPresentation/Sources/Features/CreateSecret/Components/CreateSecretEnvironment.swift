// Copyright © 2026 Devault. All rights reserved

import SwiftUI

extension EnvironmentValues {

    /// 프로젝트 목록을 로드 중인지 여부. `CreateSecretView`가 주입하면 `ProjectFieldView`가 소비.
    @Entry var isProjectLoading: Bool = false
}
