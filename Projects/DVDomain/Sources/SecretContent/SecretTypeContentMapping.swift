// Copyright © 2026 Devault. All rights reserved

public extension SecretType {
    /// subType이 없는 타입의 payload 타입. subType이 있는 타입은 SecretSubType.payloadType을 사용한다.
    var payloadType: (any SecretPayloadData.Type)? {
        switch self {
        case .database:               return DatabasePayload.self
        case .environmentVariableSet: return EnvSetPayload.self
        default:                      return nil
        }
    }

    /// subType이 없는 타입의 metadata 타입. subType이 있는 타입은 SecretSubType.metadataType을 사용한다.
    var metadataType: (any SecretMetadataContent.Type)? {
        switch self {
        case .database: return DatabaseMetadata.self
        default:        return nil
        }
    }
}

public extension SecretSubType {
    var payloadType: any SecretPayloadData.Type {
        switch self {
        case .apiKey, .accessToken, .webhookSecret: return APIKeyPayload.self
        case .oauthClient:                          return OAuthClientPayload.self
        case .serviceAccount:                       return ServiceAccountPayload.self
        case .sshKey:                               return SSHKeyPayload.self
        case .sslTlsCertificate:                    return SSLCertPayload.self
        case .licenseKey:                           return LicenseKeyPayload.self
        case .custom:                               return CustomPayload.self
        }
    }

    var metadataType: (any SecretMetadataContent.Type)? {
        switch self {
        case .apiKey, .accessToken, .webhookSecret: return APIKeyMetadata.self
        case .oauthClient:                          return OAuthClientMetadata.self
        case .serviceAccount:                       return ServiceAccountMetadata.self
        case .sshKey:                               return SSHKeyMetadata.self
        case .sslTlsCertificate:                    return SSLCertMetadata.self
        case .licenseKey:                           return LicenseKeyMetadata.self
        case .custom:                               return nil
        }
    }
}
