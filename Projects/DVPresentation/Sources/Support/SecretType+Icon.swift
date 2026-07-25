// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// 타입 선택 화면(SelectSecretType)과 목록 화면(SecretList) 아바타 폴백이 공유하는 단일 아이콘 소스.
extension SecretType {
    var icon: Image {
        Image(systemName: iconSystemName)
    }

    private var iconSystemName: String {
        switch self {
        case .apiKeyToken:            return "key.fill"
        case .oauth:                  return "checkmark.shield.fill"
        case .database:               return "cylinder.split.1x2.fill"
        case .sshAndCredentials:      return "terminal.fill"
        case .environmentVariableSet: return "curlybraces"
        case .etc:                    return "ellipsis.circle.fill"
        }
    }
}
