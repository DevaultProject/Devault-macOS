// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation
import SwiftUI

enum CreatableSecretType: String, CaseIterable, Hashable {
    case apiKeyToken
    case oauth
    case database
    case sshAndCredentials
    case environmentVariableSet
    case etc
    
    /// CreateSecret 화면의 상단 타이틀 라벨. String Catalog 룩업 대상.
    var displayName: LocalizedStringResource {
        switch self {
        case .apiKeyToken:            return .module("API Keys/Token")
        case .oauth:                  return .module("OAuth")
        case .database:               return .module("Database")
        case .sshAndCredentials:      return .module("SSH & Credentials")
        case .environmentVariableSet: return .module("EnvSet")
        case .etc:                    return .module("Etc")
        }
    }
    
    /// 상단 서브 탭바를 구성할 하위 타입 목록. 빈 배열이면 탭바 미표시.
    var availableSubTypes: [CreatableSecretSubType] {
        switch self {
        case .apiKeyToken:            return [.apiKey, .accessToken, .webhookSecret]
        case .oauth:                  return [.oauthClient, .serviceAccount]
        case .database:               return []
        case .sshAndCredentials:      return [.sshKey, .sslTlsCertificate]
        case .environmentVariableSet: return []
        case .etc:                    return [.licenseKey, .custom]
        }
    }
    
    /// 도메인 enum으로 변환할 때 사용.
    var domainType: SecretType {
        switch self {
        case .apiKeyToken:            return .apiKeyToken
        case .oauth:                  return .oauth
        case .database:               return .database
        case .sshAndCredentials:      return .sshAndCredentials
        case .environmentVariableSet: return .environmentVariableSet
        case .etc:                    return .etc
        }
    }

    /// 타입 선택 화면의 카드 아이콘. SecretList 아바타 폴백과 동일한 소스(`SecretType.icon`)를 쓴다.
    var icon: Image {
        domainType.icon
    }
}
