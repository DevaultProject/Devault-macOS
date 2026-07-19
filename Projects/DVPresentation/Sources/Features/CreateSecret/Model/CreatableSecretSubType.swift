// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

enum CreatableSecretSubType: String, CaseIterable, Hashable {
  case apiKey
  case accessToken
  case webhookSecret
  case oauthClient
  case serviceAccount
  case sshKey
  case sslTlsCertificate
  case licenseKey
  case custom

  /// `CreateSecretHeader`의 서브 탭바에 표시되는 옵션 라벨. DVPresentation 모듈의 String Catalog 룩업 대상.
  var displayName: LocalizedStringResource {
    switch self {
    case .apiKey:            return .module("API Key")
    case .accessToken:       return .module("Access Token")
    case .webhookSecret:     return .module("API Webhook Secret")
    case .oauthClient:       return .module("OAuth Client")
    case .serviceAccount:    return .module("Service Account")
    case .sshKey:            return .module("SSH Key")
    case .sslTlsCertificate: return .module("SSL/TLS Certificate")
    case .licenseKey:        return .module("License Key")
    case .custom:            return .module("Custom")
    }
  }

  /// 도메인 enum으로 변환할 때 사용.
  var domainSubType: SecretSubType {
    switch self {
    case .apiKey:            return .apiKey
    case .accessToken:       return .accessToken
    case .webhookSecret:     return .webhookSecret
    case .oauthClient:       return .oauthClient
    case .serviceAccount:    return .serviceAccount
    case .sshKey:            return .sshKey
    case .sslTlsCertificate: return .sslTlsCertificate
    case .licenseKey:        return .licenseKey
    case .custom:            return .custom
    }
  }
}
