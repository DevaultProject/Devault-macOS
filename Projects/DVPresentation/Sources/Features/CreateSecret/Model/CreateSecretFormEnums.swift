// Copyright © 2026 Devault. All rights reserved

import Foundation

/// `SecretDraft.environment`(String?)에 `rawValue`로 저장되는 Presentation VO.
enum SecretEnvironment: String, CaseIterable, Hashable {
    case dev
    case staging
    case prod
    
    /// Environment picker의 옵션 라벨. DVPresentation 모듈의 String Catalog 룩업 대상.
    var displayName: LocalizedStringResource {
        switch self {
        case .dev:     return .module("Development")
        case .staging: return .module("Staging")
        case .prod:    return .module("Production")
        }
    }
}

/// `LicenseKeyMetadata.licenseType`(String?)에 `rawValue`로 저장되는 Presentation VO.
enum LicenseTier: String, CaseIterable, Hashable {
    case individual
    case team
    case enterprise
    
    /// LicenseTier picker의 옵션 라벨. DVPresentation 모듈의 String Catalog 룩업 대상.
    var displayName: LocalizedStringResource {
        switch self {
        case .individual: return .module("Individual")
        case .team:       return .module("Team")
        case .enterprise: return .module("Enterprise")
        }
    }
}
