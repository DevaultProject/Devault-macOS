// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation

// MARK: - SecretDetailFeature

@Reducer
public struct SecretDetailFeature {

    // MARK: - Mode

    public enum Mode: Equatable {
        /// 조회 모드: Text 전용 뷰 트리. 인터랙티브 컨트롤 없음.
        case viewing
        /// 수정 모드: 기존 SectionView 재사용. editFields 바인딩 있음.
        case editing
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        /// 원본 시크릿. let — 절대 바인딩 대상이 아님.
        public let secret: Secret
        public var mode: Mode = .viewing
        /// 수정 모드에서만 유효. viewing일 때는 반드시 nil.
        var editFields: SecretMetaFields?
        public var availableProjects: [Project] = []
        public var isSaving = false
        public var isLoadingProjects = false
        /// 복호화된 payload. .idle → .loading → .loaded / .failed 순서로 전이.
        public var payloadState: LoadingState<CreateSecretPayload, SecretUseCaseError> = .idle
        @Presents public var alert: AlertState<Action.Alert>?

        public init(secret: Secret) {
            self.secret = secret
        }
    }

    // MARK: - Action

    public enum Action: BindableAction, Equatable {

        // MARK: View
        case task
        case binding(BindingAction<State>)
        case didTapClose
        case didTapEdit
        case didTapCancelEdit
        case didTapSave

        // MARK: Internal
        case projectsResponse(Result<[Project], ProjectUseCaseError>)
        case payloadResponse(Result<CreateSecretPayload, SecretUseCaseError>)

        // MARK: Child
        case alert(PresentationAction<Alert>)

        // MARK: Delegate
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmDiscard
        }

        public enum Delegate: Equatable {
            case closed
            case secretUpdated(Secret)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.projectClient) var projectClient
    @Dependency(\.secretClient) var secretClient

    // MARK: - Init

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoadingProjects = true
                state.payloadState = .loading
                return .merge(
                    .run { send in
                        do {
                            let projects = try await projectClient.fetchProjects()
                            await send(.projectsResponse(.success(projects)))
                        } catch is CancellationError {
                        } catch {
                            await send(.projectsResponse(.failure(.unexpected)))
                        }
                    },
                    .run { [secret = state.secret] send in
                        do {
                            let payload = try await secretClient.revealPayload(secret)
                            await send(.payloadResponse(.success(payload)))
                        } catch is CancellationError {
                        } catch {
                            await send(.payloadResponse(.failure(SecretUseCaseError.map(error))))
                        }
                    }
                )

            case .didTapClose:
                return .send(.delegate(.closed))

            case .projectsResponse(.success(let projects)):
                state.isLoadingProjects = false
                state.availableProjects = projects
                return .none

            case .projectsResponse(.failure):
                state.isLoadingProjects = false
                return .none

            case .payloadResponse(.success(let payload)):
                state.payloadState = .loaded(payload)
                return .none

            case .payloadResponse(.failure(let error)):
                state.payloadState = .failed(error)
                state.alert = .payloadRevealFailed(SecretDetailError.map(error))
                return .none

            case .didTapEdit, .didTapCancelEdit, .didTapSave:
                return .none

            case .binding, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
