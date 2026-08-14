// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("DeleteAllDataUseCaseImpl")
struct DeleteAllDataUseCaseImplTests {

    @Test("인증 후 활성/휴지통 Secret과 Project를 모두 영구 삭제한다")
    func executeDeletesEverything() async throws {
        let secretRepository = InMemorySecretRepository()
        let projectRepository = InMemoryProjectRepository()

        let activeSecret = SecretFixture.make()
        var trashedSecret = SecretFixture.make()
        trashedSecret.deletedAt = Date()
        secretRepository.seed(activeSecret)
        secretRepository.seed(trashedSecret)

        let project = ProjectFixture.make()
        projectRepository.seed(project)

        let sut = DeleteAllDataUseCaseImpl(
            secretRepository: secretRepository,
            projectRepository: projectRepository,
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: StubUserAuthenticationService(),
                notificationService: FakeSecurityNotificationService()
            )
        )

        try await sut.execute()

        #expect(try await secretRepository.fetch(id: activeSecret.id) == nil)
        #expect(try await secretRepository.fetch(id: trashedSecret.id) == nil)
        #expect(try await projectRepository.fetch(id: project.id) == nil)
    }

    @Test("인증에 실패하면 아무것도 삭제하지 않는다")
    func executeDoesNothingWhenAuthenticationFails() async {
        let secretRepository = InMemorySecretRepository()
        let projectRepository = InMemoryProjectRepository()
        let secret = SecretFixture.make()
        secretRepository.seed(secret)

        let authenticationService = StubUserAuthenticationService()
        authenticationService.errorOnAuthenticate = .cancelled
        let sut = DeleteAllDataUseCaseImpl(
            secretRepository: secretRepository,
            projectRepository: projectRepository,
            authenticateUseCase: AuthenticateUseCaseImpl(
                authenticationService: authenticationService,
                notificationService: FakeSecurityNotificationService()
            )
        )

        await #expect(throws: UserAuthenticationError.cancelled) {
            try await sut.execute()
        }
        #expect(try await secretRepository.fetch(id: secret.id) != nil)
    }
}
