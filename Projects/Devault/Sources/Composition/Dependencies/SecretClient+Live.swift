// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVData
import DVDomain
import DVPresentation
import Foundation

extension SecretClient: @retroactive DependencyKey {
    public static let liveValue: SecretClient = {
        let secretRepo = LiveRepositories.secret
        let projectRepo = LiveRepositories.project
        let cryptoService: any SecretCryptoService = SecretCryptoServiceImpl()
        let authService: any UserAuthenticationService = LocalUserAuthenticationServiceImpl()

        let fetchSecretUseCase: any FetchSecretUseCase = FetchSecretUseCaseImpl(
            repository: secretRepo,
            cryptoService: cryptoService,
            authenticationService: authService
        )
        let deleteSecretUseCase: any DeleteSecretUseCase = DeleteSecretUseCaseImpl(
            repository: secretRepo
        )
        let relationUseCase: any SecretProjectRelationUseCase = SecretProjectRelationUseCaseImpl(
            repository: secretRepo
        )
        let patchSecretUseCase: any PatchSecretUseCase = PatchSecretUseCaseImpl(
            repository: secretRepo,
            cryptoService: cryptoService
        )
        let fetchProjectUseCase: any FetchProjectUseCase = FetchProjectUseCaseImpl(
            repository: projectRepo
        )
        let createProjectUseCase: any CreateProjectUseCase = CreateProjectUseCaseImpl(
            repository: projectRepo
        )

        return SecretClient(
            fetchByQuery: { query in
                try await fetchSecretUseCase.fetch(query: query)
            },
            softDelete: { id in
                try await deleteSecretUseCase.softDelete(id: id)
            },
            restore: { id in
                try await deleteSecretUseCase.restore(id: id)
            },
            permanentlyDelete: { id in
                try await deleteSecretUseCase.permanentlyDelete(id: id)
            },
            revealPayload: { secret in
                try await dispatchRevealPayload(secret: secret, useCase: fetchSecretUseCase)
            },
            setLiked: { id, liked in
                try await patchSecretUseCase.updateSimple(
                    id: id,
                    with: SecretPatch(liked: .set(liked))
                )
            },
            fetchLinkedProjects: { secretID in
                try await fetchSecretUseCase.fetchProjects(secretID: secretID)
            },
            fetchProjects: {
                try await fetchProjectUseCase.fetchAll()
            },
            createProject: { name in
                try await createProjectUseCase.execute(name: name)
            },
            linkProject: { secretID, projectID in
                try await relationUseCase.link(secretID: secretID, projectID: projectID)
            }
        )
    }()
}

// MARK: - Payload Dispatch

private func dispatchRevealPayload(
    secret: Secret,
    useCase: any FetchSecretUseCase
) async throws -> CreateSecretPayload {
    func decodeMeta<M: SecretMetadataContent>(_ type: M.Type) -> M? {
        secret.metadata.flatMap { try? JSONDecoder().decode(M.self, from: $0.metadataJSON) }
    }

    switch (secret.secretType, secret.subType) {
    case (.apiKeyToken, .apiKey), (.apiKeyToken, nil):
        let p = try await useCase.revealPayload(id: secret.id, as: APIKeyPayload.self)
        return .apiKey(p, decodeMeta(APIKeyMetadata.self))
    case (.apiKeyToken, .accessToken):
        let p = try await useCase.revealPayload(id: secret.id, as: APIKeyPayload.self)
        return .accessToken(p, decodeMeta(APIKeyMetadata.self))
    case (.apiKeyToken, .webhookSecret):
        let p = try await useCase.revealPayload(id: secret.id, as: APIKeyPayload.self)
        return .webhookSecret(p, decodeMeta(APIKeyMetadata.self))
    case (.oauth, .oauthClient), (.oauth, nil):
        let p = try await useCase.revealPayload(id: secret.id, as: OAuthClientPayload.self)
        return .oauthClient(p, decodeMeta(OAuthClientMetadata.self))
    case (.oauth, .serviceAccount):
        let p = try await useCase.revealPayload(id: secret.id, as: ServiceAccountPayload.self)
        return .serviceAccount(p, decodeMeta(ServiceAccountMetadata.self))
    case (.database, _):
        let p = try await useCase.revealPayload(id: secret.id, as: DatabasePayload.self)
        return .database(p, decodeMeta(DatabaseMetadata.self))
    case (.sshAndCredentials, .sshKey), (.sshAndCredentials, nil):
        let p = try await useCase.revealPayload(id: secret.id, as: SSHKeyPayload.self)
        return .sshKey(p, decodeMeta(SSHKeyMetadata.self))
    case (.sshAndCredentials, .sslTlsCertificate):
        let p = try await useCase.revealPayload(id: secret.id, as: SSLCertPayload.self)
        return .sslTlsCertificate(p, decodeMeta(SSLCertMetadata.self))
    case (.environmentVariableSet, _):
        let p = try await useCase.revealPayload(id: secret.id, as: EnvSetPayload.self)
        return .environmentVariableSet(p)
    case (.etc, .licenseKey), (.etc, nil):
        let p = try await useCase.revealPayload(id: secret.id, as: LicenseKeyPayload.self)
        return .licenseKey(p, decodeMeta(LicenseKeyMetadata.self))
    case (.etc, .custom):
        let p = try await useCase.revealPayload(id: secret.id, as: CustomPayload.self)
        return .custom(p)
    default:
        assertionFailure("Unexpected (secretType, subType) combination: \(secret.secretType), \(String(describing: secret.subType))")
        throw SecretUseCaseError.unexpected
    }
}
