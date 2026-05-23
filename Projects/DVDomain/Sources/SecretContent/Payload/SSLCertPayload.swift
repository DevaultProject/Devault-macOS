// Copyright © 2026 Devault. All rights reserved

public struct SSLCertPayload: SecretPayloadData, Equatable {
    public static let schemaVersion = 1

    public var certificate: String
    public var privateKey: String
    public var certificateChain: String?

    public init(
        certificate: String,
        privateKey: String,
        certificateChain: String? = nil
    ) {
        self.certificate = certificate
        self.privateKey = privateKey
        self.certificateChain = certificateChain
    }
}
