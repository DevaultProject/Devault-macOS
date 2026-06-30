import DVData
import DVDomain
import DVPresentation
import SwiftUI

struct ContentView: View {
    private let repository: SecretRepositoryImpl
    private let cryptoService = SecretCryptoServiceImpl()
    private let authenticationService = LocalUserAuthenticationServiceImpl()

    init(storage: LocalStorage) {
        self.repository = SecretRepositoryImpl(modelContainer: storage.modelContainer)
    }

    var body: some View {
        SecretUseCaseDemoView(
            createSecretUseCase: CreateSecretUseCaseImpl(
                repository: repository,
                cryptoService: cryptoService
            ),
            fetchSecretUseCase: FetchSecretUseCaseImpl(
                repository: repository,
                cryptoService: cryptoService,
                authenticationService: authenticationService
            )
        )
    }
}
