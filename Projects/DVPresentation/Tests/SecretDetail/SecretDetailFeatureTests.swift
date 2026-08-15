// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import ComposableArchitecture
import DVDomain

@testable import DVPresentation

@Suite("SecretDetailFeature")
@MainActor
struct SecretDetailFeatureTests {

    /// reveal 인증 창 판정이 실행 시점에 흔들리지 않도록 고정한다.
    private static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Helpers

    private static func makeSecret(
        name: String = "Test Secret",
        secretType: SecretType = .apiKeyToken,
        liked: Bool = false
    ) -> Secret {
        Secret(
            id: UUID(),
            name: name,
            secretType: secretType,
            liked: liked,
            createdAt: Date(),
            updatedAt: Date(),
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
    }

    // MARK: - Viewing 진입

    @Test("초기 mode는 .viewing이다")
    func initialModeIsViewing() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        store.assert { state in
            #expect(state.mode == .viewing)
            #expect(state.editFields == nil)
        }
    }

    // `task`가 거는 것은 연결 프로젝트 조회와 lifecycle 구독 둘뿐이다. 후자는 테스트 환경에서
    // 곧바로 끝나는 스트림이라 액션을 내지 않으므로, 수신 순서를 맞출 필요가 없다.

    /// 진입이 아니라 눈 버튼이 복호화를 유발한다. 복호화는 인증을 통과해야 성공하므로
    /// 도착 자체가 인증 성공이고, 그 시각으로 재인증 창이 열린다.
    @Test("눈 버튼: 값이 없으면 복호화하고 그 필드를 연다")
    func toggleReveal_decryptsAndOpensField() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "test_token"), nil)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in payload }
            $0.date = .constant(Self.referenceDate)
        }

        await store.send(.didTapToggleReveal(.value)) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.success(payload), revealing: .value, thenCopy: nil)) {
            $0.payloadState = .loaded(payload)
            $0.revealAuthorizedAt = Self.referenceDate
            $0.revealedFields = [.value]
        }
    }

    @Test("눈 버튼 복호화 실패: payloadState .failed + alert 노출")
    func toggleReveal_decryptionFailure() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.cryptoFailure(.decryptionFailed) }
        }

        await store.send(.didTapToggleReveal(.value)) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.failure(.cryptoFailure(.decryptionFailed)), revealing: .value, thenCopy: nil)) {
            $0.payloadState = .failed(.cryptoFailure(.decryptionFailed))
            $0.alert = .payloadRevealFailed(.decryptionFailed)
        }
    }

    @Test("눈 버튼 인증 실패: authRequired alert 노출")
    func toggleReveal_authenticationFailure() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.authenticationFailure(.cancelled) }
        }

        await store.send(.didTapToggleReveal(.value)) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.failure(.authenticationFailure(.cancelled)), revealing: .value, thenCopy: nil)) {
            $0.payloadState = .failed(.authenticationFailure(.cancelled))
            $0.alert = .payloadRevealFailed(.authRequired)
        }
    }

    @Test("task: 연결된 프로젝트 로드 성공")
    func task_linkedProjectsSuccess() async {
        let secret = Self.makeSecret()
        let linked = [
            Project(id: UUID(), name: "Backend", createdAt: Date(), updatedAt: Date()),
        ]

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.fetchLinkedProjects = { _ in linked }
        }

        // 진입은 복호화를 시작하지 않는다. `revealPayload`를 스텁하지 않았으므로
        // 진입이 복호화를 걸면 미구현 dependency 호출로 이 테스트가 실패한다.
        await store.send(.task)
        await store.receive(.linkedProjectsResponse(.success(linked))) {
            $0.linkedProjects = linked
        }
    }

    /// 모든 실패를 알린다는 정책에 따라 이 경로도 alert를 띄운다.
    /// 진입 시 복호화를 하지 않게 되면서 복호화 실패 alert와 겹칠 일이 없어졌다.
    @Test("연결된 프로젝트 조회 실패도 alert를 띄운다")
    func task_linkedProjectsFailure_showsAlert() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.fetchLinkedProjects = { _ in throw SecretUseCaseError.unexpected }
        }

        // 진입은 복호화를 시작하지 않는다. `revealPayload`를 스텁하지 않았으므로
        // 진입이 복호화를 걸면 미구현 dependency 호출로 이 테스트가 실패한다.
        await store.send(.task)
        await store.receive(.linkedProjectsResponse(.failure(.unexpected))) {
            $0.alert = .projectsLoadFailed
        }
        // 값은 비어 있을 뿐 다른 정보는 영향받지 않는다.
        #expect(store.state.linkedProjects.isEmpty)
    }

    // MARK: - payload 재시도

    // `didTapRetryReveal`은 effect가 reveal 하나뿐이라 수신 순서를 맞출 필요가 없다.

    @Test("didTapRetryReveal 성공: payloadState .loading → .loaded")
    func retryReveal_success() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "test_token"), nil)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in payload }
            $0.date = .constant(Self.referenceDate)
        }

        await store.send(.didTapRetryReveal) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.success(payload), revealing: nil, thenCopy: nil)) {
            $0.payloadState = .loaded(payload)
            $0.revealAuthorizedAt = Self.referenceDate
        }
    }

    @Test("didTapRetryReveal 실패: payloadState .failed + alert 노출")
    func retryReveal_failure() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in throw SecretUseCaseError.cryptoFailure(.decryptionFailed) }
        }

        await store.send(.didTapRetryReveal) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.failure(.cryptoFailure(.decryptionFailed)), revealing: nil, thenCopy: nil)) {
            $0.payloadState = .failed(.cryptoFailure(.decryptionFailed))
            $0.alert = .payloadRevealFailed(.decryptionFailed)
        }
    }

    @Test("인증 취소 후 재시도: alert를 닫고 다시 시도하면 payload가 노출된다")
    func retryReveal_afterAuthenticationCancellation() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "test_token"), nil)
        let attemptCount = LockIsolated(0)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.date = .constant(Self.referenceDate)
            $0.secretClient.revealPayload = { _ in
                let attempt = attemptCount.withValue { count -> Int in
                    count += 1
                    return count
                }
                // 첫 시도는 Touch ID 취소, 재시도는 성공.
                if attempt == 1 {
                    throw SecretUseCaseError.authenticationFailure(.cancelled)
                }
                return payload
            }
        }

        await store.send(.didTapToggleReveal(.value)) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.failure(.authenticationFailure(.cancelled)), revealing: .value, thenCopy: nil)) {
            $0.payloadState = .failed(.authenticationFailure(.cancelled))
            $0.alert = .payloadRevealFailed(.authRequired)
        }

        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }

        await store.send(.didTapRetryReveal) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.success(payload), revealing: nil, thenCopy: nil)) {
            $0.payloadState = .loaded(payload)
            $0.revealAuthorizedAt = Self.referenceDate
        }
        // 매 시도가 생체인증을 새로 타므로 호출 횟수 자체가 재시도 성립의 근거다.
        #expect(attemptCount.value == 2)
    }

    // MARK: - reveal 인증 창

    /// 창이 열려 있는 동안에는 다른 필드를 열어도 인증을 다시 요구하지 않는다.
    @Test("인증 창이 열려 있으면 다른 필드는 인증 없이 열린다")
    func toggleReveal_withinWindow_skipsAuthentication() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.oauthClient(
            OAuthClientPayload(clientId: "id", clientSecret: "secret"), nil
        )

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)
        state.revealAuthorizedAt = Self.referenceDate
        state.revealedFields = [.clientId]

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            // 인증을 부르면 미구현 dependency 호출로 실패하므로, 호출하지 않는다는 것 자체가 검증된다.
            $0.date = .constant(Self.referenceDate.addingTimeInterval(60))
        }

        await store.send(.didTapToggleReveal(.clientSecret)) {
            $0.revealedFields = [.clientId, .clientSecret]
        }
    }

    /// 창이 닫힌 뒤에는 값이 이미 있어도 인증을 다시 받는다. 복호화는 하지 않는다.
    @Test("창이 만료되면 인증만 다시 받고 복호화는 하지 않는다")
    func toggleReveal_afterExpiry_reauthenticatesOnly() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "token"), nil)
        let expired = Self.referenceDate.addingTimeInterval(-1_000)

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)
        state.revealAuthorizedAt = expired

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.authenticate = { _ in }
            $0.date = .constant(Self.referenceDate)
        }

        await store.send(.didTapToggleReveal(.value))
        await store.receive(.reauthenticateResponse(.success(true), revealing: .value)) {
            $0.revealAuthorizedAt = Self.referenceDate
            $0.revealedFields = [.value]
        }
    }

    @Test("재인증 실패: 필드가 열리지 않고 alert가 뜬다")
    func reauthenticate_failure_showsAlert() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "token"), nil)

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)
        state.revealAuthorizedAt = Self.referenceDate.addingTimeInterval(-1_000)

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.authenticate = { _ in throw SecretUseCaseError.unexpected }
            $0.date = .constant(Self.referenceDate)
        }

        await store.send(.didTapToggleReveal(.value))
        await store.receive(.reauthenticateResponse(.success(false), revealing: .value)) {
            $0.alert = .payloadRevealFailed(.authRequired)
        }
        #expect(store.state.revealedFields.isEmpty)
    }

    /// 닫는 방향은 노출을 줄이므로 인증을 타지 않는다.
    @Test("열린 필드를 닫을 때는 인증하지 않는다")
    func toggleReveal_closing_needsNoAuthentication() async {
        let secret = Self.makeSecret()
        var state = SecretDetailFeature.State(secret: secret)
        state.revealedFields = [.value]

        let store = TestStore(initialState: state) { SecretDetailFeature() }

        await store.send(.didTapToggleReveal(.value)) {
            $0.revealedFields = []
        }
    }

    // MARK: - 생명주기 무효화

    @Test("무효화 대상 사건이 오면 인증 창과 열린 필드가 모두 닫힌다")
    func lifecycleEvent_invalidatesRevealState() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "token"), nil)

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)
        state.revealAuthorizedAt = Self.referenceDate
        state.revealedFields = [.value]

        let store = TestStore(initialState: state) { SecretDetailFeature() }

        await store.send(.lifecycleEvent(.didEnterBackground)) {
            $0.revealAuthorizedAt = nil
            $0.revealedFields = []
        }
        // 값 자체는 남는다 — 다시 열 때 인증만 받으면 되고 재복호화는 불필요한 비용이다.
        #expect(store.state.payloadState == .loaded(payload))
    }

    @Test("정책이 무시하는 사건은 상태를 건드리지 않는다")
    func lifecycleEvent_ignoredByPolicy_keepsState() async {
        let secret = Self.makeSecret()
        var state = SecretDetailFeature.State(secret: secret)
        state.revealAuthorizedAt = Self.referenceDate
        state.revealedFields = [.value]

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            $0.revealAuthPolicy = RevealAuthPolicy(
                ttl: 180,
                invalidatesOnBackground: false,
                invalidatesOnLock: true
            )
        }

        await store.send(.lifecycleEvent(.didEnterBackground))
    }

    // MARK: - 복사

    @Test("값이 있으면 복호화 없이 원문을 복사한다")
    func copy_withLoadedPayload_copiesPlainValue() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_secret"), nil)
        let copied = LockIsolated<String?>(nil)

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.copySensitiveValue = { value in
                copied.withValue { $0 = value }
            }
        }

        await store.send(.didTapCopy(.value))
        await store.receive(.copyResponse(.success(true)))
        // 마스킹 여부와 무관하게 원문이 들어가야 한다.
        #expect(copied.value == "ghp_secret")
    }

    /// 복사가 인증을 유발하는 것이 아니라, 값이 없어 복호화가 필요한 것이 유발한다.
    @Test("값이 없으면 복호화한 뒤 이어서 복사한다")
    func copy_withoutPayload_decryptsThenCopies() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_secret"), nil)
        let copied = LockIsolated<String?>(nil)

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in payload }
            $0.secretClient.copySensitiveValue = { value in
                copied.withValue { $0 = value }
            }
            $0.date = .constant(Self.referenceDate)
        }

        await store.send(.didTapCopy(.value)) {
            $0.payloadState = .loading
        }
        await store.receive(.payloadResponse(.success(payload), revealing: nil, thenCopy: .value)) {
            $0.payloadState = .loaded(payload)
            $0.revealAuthorizedAt = Self.referenceDate
        }
        await store.receive(.copyResponse(.success(true)))
        #expect(copied.value == "ghp_secret")
        // 복사는 마스킹을 풀지 않는다.
        #expect(store.state.revealedFields.isEmpty)
    }

    @Test("복사 실패: alert가 뜬다")
    func copy_failure_showsAlert() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.apiKey(APIKeyPayload(value: "ghp_secret"), nil)

        var state = SecretDetailFeature.State(secret: secret)
        state.payloadState = .loaded(payload)

        let store = TestStore(initialState: state) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.copySensitiveValue = { _ in throw ClipboardError.writeFailed }
        }

        await store.send(.didTapCopy(.value))
        await store.receive(.copyResponse(.success(false))) {
            $0.alert = .copyFailed
        }
    }

    /// 복사 대기는 그 복사를 유발한 복호화에만 딸린 것이다. 다른 필드를 여느라 복호화가
    /// 새로 걸리면 대기도 함께 사라져야 한다 — 눈 버튼을 눌렀는데 다른 필드가 클립보드에
    /// 들어가면 사용자가 알 방법이 없다.
    @Test("복사 대기 중 다른 필드를 열면 대기 중이던 복사는 사라진다")
    func pendingCopy_supersededByReveal_doesNotCopy() async {
        let secret = Self.makeSecret()
        let payload = CreateSecretPayload.oauthClient(
            OAuthClientPayload(clientId: "client-id", clientSecret: "client-secret"),
            nil
        )
        let copied = LockIsolated<String?>(nil)
        let clock = TestClock()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in
                try await clock.sleep(for: .seconds(1))
                return payload
            }
            $0.secretClient.copySensitiveValue = { value in
                copied.withValue { $0 = value }
            }
            $0.date = .constant(Self.referenceDate)
        }

        // 값이 없는 상태에서 Client Secret 복사 → 복호화가 걸리고 복사는 대기한다.
        await store.send(.didTapCopy(.clientSecret)) {
            $0.payloadState = .loading
        }

        // 응답 전에 Client ID의 눈 버튼. 같은 CancelID라 앞 복호화가 취소되고 새로 시작한다.
        await store.send(.didTapToggleReveal(.clientId))

        await clock.advance(by: .seconds(1))
        await store.receive(.payloadResponse(.success(payload), revealing: .clientId, thenCopy: nil)) {
            $0.payloadState = .loaded(payload)
            $0.revealAuthorizedAt = Self.referenceDate
            $0.revealedFields = [.clientId]
        }

        #expect(copied.value == nil)
    }

    /// 평문 필드(Redirect URL·Public Key·Renew Command)는 payload에 없어 꺼낼 식별자가 없다.
    /// 값을 그대로 받아 복사한다.
    ///
    /// `revealPayload`와 `copySensitiveValue`를 **일부러 스텁하지 않는다** — 둘 중 하나라도 불리면
    /// 미구현 dependency 호출로 실패한다. 평문을 보는 데 인증을 요구하지 않는다는 것과,
    /// 비밀이 아닌 값에 자동 정리·반복 감지를 씌우지 않는다는 것이 이렇게 고정된다.
    @Test("평문 필드 복사: 복호화도 민감 값 정책도 타지 않는다")
    func copyPlainValue_bypassesRevealAndSensitivePolicy() async {
        let secret = Self.makeSecret()
        let copied = LockIsolated<String?>(nil)
        let redirectURL = "https://app.example/oauth/callback"

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.copyPlainValue = { value in
                copied.withValue { $0 = value }
            }
        }

        await store.send(.didTapCopyPlainValue(redirectURL))
        await store.receive(.copyResponse(.success(true)))
        #expect(copied.value == redirectURL)
        #expect(store.state.payloadState == .idle)
    }

    @Test("평문 복사 실패도 alert를 띄운다")
    func copyPlainValue_failure_showsAlert() async {
        let secret = Self.makeSecret()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.copyPlainValue = { _ in throw ClipboardError.writeFailed }
        }

        await store.send(.didTapCopyPlainValue("https://app.example/oauth/callback"))
        await store.receive(.copyResponse(.success(false))) {
            $0.alert = .copyFailed
        }
    }

    // MARK: - Close delegate

    @Test("didTapClose는 delegate(.closed)를 emit한다")
    func didTapClose_emitsClosedDelegate() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        await store.send(.didTapClose)
        await store.receive(.delegate(.closed))
    }

    // MARK: - 즐겨찾기

    @Test("didTapToggleLike 성공: secret 교체 + secretUpdated delegate")
    func toggleLike_success() async {
        let secret = Self.makeSecret(liked: false)
        var updated = secret
        updated.liked = true

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, _ in updated }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.success(updated))) {
            $0.secret = updated
        }
        await store.receive(.delegate(.secretUpdated(updated)))
    }

    @Test("didTapToggleLike는 현재 liked의 반대값을 전달한다")
    func toggleLike_sendsInvertedValue() async {
        let secret = Self.makeSecret(liked: true)
        var updated = secret
        updated.liked = false

        let requestedLiked = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, liked in
                requestedLiked.setValue(liked)
                return updated
            }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.success(updated))) {
            $0.secret = updated
        }
        await store.receive(.delegate(.secretUpdated(updated)))
        #expect(requestedLiked.value == false)
    }

    @Test("didTapToggleLike 실패: alert 노출 + secret 유지")
    func toggleLike_failure() async {
        let secret = Self.makeSecret(liked: false)
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.setLiked = { _, _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.didTapToggleLike)
        await store.receive(.likeResponse(.failure(.unexpected))) {
            $0.alert = .likeFailed
        }
        #expect(store.state.secret.liked == false)
    }

    // MARK: - 삭제

    @Test("didTapDelete는 즉시 삭제하지 않고 확인 alert를 띄운다")
    func didTapDelete_presentsConfirmAlert() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
    }

    @Test("confirmDelete 성공: deleted delegate emit")
    func confirmDelete_success() async {
        let secret = Self.makeSecret()
        var deleted = secret
        deleted.deletedAt = Date()

        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in deleted }
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
            $0.isDeleting = true
        }
        await store.receive(.deleteResponse(.success(deleted))) {
            $0.isDeleting = false
        }
        await store.receive(.delegate(.deleted(secret.id)))
    }

    @Test("confirmDelete 실패: isDeleting 해제 + alert 노출")
    func confirmDelete_failure() async {
        let secret = Self.makeSecret()
        let store = TestStore(initialState: SecretDetailFeature.State(secret: secret)) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.softDelete = { _ in throw SecretUseCaseError.unexpected }
        }

        await store.send(.didTapDelete) {
            $0.alert = .confirmDelete
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
            $0.isDeleting = true
        }
        await store.receive(.deleteResponse(.failure(.unexpected))) {
            $0.isDeleting = false
            $0.alert = .deleteFailed
        }
    }
}
