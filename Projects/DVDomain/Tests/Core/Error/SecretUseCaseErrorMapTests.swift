// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("SecretUseCaseError.map")
struct SecretUseCaseErrorMapTests {
    @Test("SecretUseCaseError는 그대로 통과된다")
    func passesThroughSelf() {
        let mapped = SecretUseCaseError.map(SecretUseCaseError.invalidName)

        #expect(mapped == .invalidName)
    }

    @Test("SecretRepositoryError.notFound는 secretNotFound로 매핑된다")
    func mapsRepositoryNotFound() {
        let id = UUID()
        let mapped = SecretUseCaseError.map(SecretRepositoryError.notFound(id: id))

        #expect(mapped == .secretNotFound(id: id))
    }

    @Test("그 외 SecretRepositoryError는 repositoryFailure로 감싼다")
    func wrapsOtherRepositoryErrors() {
        let mapped = SecretUseCaseError.map(SecretRepositoryError.storageUnavailable)

        #expect(mapped == .repositoryFailure(.storageUnavailable))
    }

    @Test("SecretCryptoError는 cryptoFailure로 매핑된다")
    func mapsCryptoError() {
        let mapped = SecretUseCaseError.map(SecretCryptoError.decryptionFailed)

        #expect(mapped == .cryptoFailure(.decryptionFailed))
    }

    @Test("UserAuthenticationError는 authenticationFailure로 매핑된다")
    func mapsAuthenticationError() {
        let mapped = SecretUseCaseError.map(UserAuthenticationError.cancelled)

        #expect(mapped == .authenticationFailure(.cancelled))
    }

    @Test("알 수 없는 Error는 unexpected로 매핑된다")
    func mapsUnknownAsUnexpected() {
        struct UnknownError: Error {}
        let mapped = SecretUseCaseError.map(UnknownError())

        #expect(mapped == .unexpected)
    }
}
