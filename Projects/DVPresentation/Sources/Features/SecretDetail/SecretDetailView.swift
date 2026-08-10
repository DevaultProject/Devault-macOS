// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import ComposableArchitecture
import DVDesign
import DVDomain

// MARK: - SecretDetailView

public struct SecretDetailView: View {

    // MARK: - Properties

    @Bindable public var store: StoreOf<SecretDetailFeature>

    // MARK: - Init

    public init(store: StoreOf<SecretDetailFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        // 필드 폭은 컨테이너 폭에서 파생된다. detail 컬럼은 기본적으로 가변 폭 1열(.detailFluid)이고,
        // 컬럼이 2열 임계값(816)을 넘으면 CreateSecret과 같은 .dual 배열로 전환된다.
        GeometryReader { proxy in
            let layout = DetailColumnFormLayout.layout(for: proxy.size.width)
            VStack(spacing: 0) {
                Group {
                    if store.mode == .viewing {
                        viewingBody
                    } else {
                        editingBody
                    }
                }
                if store.mode == .editing {
                    Divider()
                    HStack {
                        Spacer()
                        Button("Cancel") { store.send(.didTapCancelEdit) }
                            .buttonStyle(.plain)
                        Button("Save") { store.send(.didTapSave) }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            // 프레임 상한. header/footer는 본문과 분리된 채 각자 이 프레임을 따라간다.
            .formMaxWidth()
            .formLayout(layout)
        }
        // `id:`가 필수다. 다른 리스트 셀을 선택하면 MainFeature가 `secretDetail`에 **새 State**를
        // 할당하지만, 뷰의 타입·위치가 그대로라 SwiftUI는 뷰를 재생성하지 않는다.
        // 그러면 평범한 `.task`는 다시 실행되지 않아 `linkedProjects` / `payloadState`가 빈 채로 남는다
        // (`store.secret`을 직접 읽는 헤더·Name만 갱신되어 더 헷갈린다).
        //
        // `finish()`를 await하는 것도 함께 필요하다 — secret이 바뀔 때 이전 secret의 조회 effect가
        // 취소되어야 늦게 도착한 응답이 새 State를 덮어쓰지 않는다.
        .task(id: store.secret.id) {
            await store.send(.task).finish()
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

extension SecretDetailView {

    // MARK: Viewing

    /// 복호화된 payload가 도착한 뒤에만 타입별 섹션을 렌더한다 — 어떤 섹션을 그릴지는
    /// `DetailPayloadSectionView`가 payload case로 결정한다.
    ///
    /// 복호화 전에는 필드 스캐폴드를 **뷰 트리에서 제외**한다. 반투명 오버레이로 덮으면
    /// 뒤의 필드가 비쳐 보여 어수선하다. 헤더는 두 경우 모두 남는다 —
    /// 즐겨찾기·삭제는 복호화 없이 수행되므로 로딩 중에도 열려 있어야 한다.
    @ViewBuilder
    private var viewingBody: some View {
        if case .loaded(let payload) = store.payloadState {
            ScrollView {
                bodyStack {
                    DetailPayloadSectionView(
                        secret: store.secret,
                        linkedProjects: store.linkedProjects,
                        payload: payload
                    )
                }
            }
        } else {
            // ScrollView로 감싸지 않는다 — 감싸면 상태 뷰가 남은 높이를 채우지 못해
            // 헤더 바로 아래에 작게 붙는다.
            bodyStack {
                payloadStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// 헤더 + 본문 공통 컨테이너. 복호화 전후로 padding·정렬이 어긋나지 않게 한곳에 둔다.
    private func bodyStack<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            content()
        }
        .padding(.horizontal, FormLayoutMetrics.horizontalPadding)
        .padding(.vertical, FormLayoutMetrics.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        SecretDetailHeaderView(
            secretType: store.secret.secretType,
            subType: store.secret.subType,
            isLiked: store.secret.liked,
            // 편집 모드는 후속 이슈 범위 — 상태 전이가 없어 비활성으로 렌더한다.
            isEditEnabled: false,
            onToggleLike: { store.send(.didTapToggleLike) },
            onEdit: { store.send(.didTapEdit) },
            onDelete: { store.send(.didTapDelete) }
        )
        .disabled(store.isDeleting)
    }

    // MARK: Payload state

    /// 스크림이 없다 — 필드 스캐폴드가 뷰 트리에서 빠져 있어 덮을 대상이 없다.
    @ViewBuilder
    private var payloadStateView: some View {
        switch store.payloadState {
        // `.idle`은 `.task`가 즉시 `.loading`으로 바꾸므로 실제로 노출되지 않는다.
        case .idle, .loading:
            payloadLoadingView

        case .failed(let error):
            payloadFailureView(SecretDetailError.map(error))

        case .loaded:
            EmptyView()
        }
    }

    private var payloadLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text(.module("Decrypting secret…"))
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray500))
        }
    }

    private func payloadFailureView(_ error: SecretDetailError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .dvFont(.bodyLG)
                .foregroundStyle(Color.dv(.gray400))
            Text(error.revealFailureMessage)
                .dvFont(.bodyMD)
                .foregroundStyle(Color.dv(.gray500))
                .multilineTextAlignment(.center)
            DVButton(titleText: .module("Retry"), style: .secondary) {
                store.send(.didTapRetryReveal)
            }
        }
        .padding(.horizontal, FormLayoutMetrics.horizontalPadding)
    }

    // MARK: Editing

    /// 편집 모드 진입 경로가 아직 없어 도달하지 않는다. 후속 이슈에서
    /// `editFields` 바인딩과 SectionView 재사용으로 채운다.
    @ViewBuilder
    private var editingBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.secret.name)
                    .dvFont(.headingLG)
                    .foregroundStyle(Color.dv(.gray900))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

/// 화면 프리뷰는 payload **상태**를 확인하는 자리다 — 타입별 섹션 조합은
/// `DetailPayloadSectionView`의 sweep 프리뷰가 담당하므로 여기서 조합을 늘리지 않는다.
private let _previewSecret = [Secret].previewSubTypeMatrix[0]

/// `dummyClient().revealPayload`가 `matrix[0]`(apiKey)에 맞는 payload를 돌려주므로
/// 별도 스텁 없이 `.loaded` 경로가 그려진다.
#Preview("SecretDetail · Payload Loaded") {
    SecretDetailView(
        store: Store(
            initialState: SecretDetailFeature.State(secret: _previewSecret)
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

/// 인증 전 배치 확인용 — 헤더만 남고 필드 스캐폴드는 뷰 트리에서 빠져, 남은 영역을 로딩 뷰가 채운다.
///
/// `.task`가 진입 즉시 `payloadState`를 다시 쓰므로 초기 상태만으로는 상태가 유지되지 않는다.
/// 응답하지 않는 스텁을 함께 넣어 로딩 표현을 화면에 남긴다.
#Preview("SecretDetail · Payload Loading") {
    SecretDetailView(
        store: Store(
            initialState: {
                var state = SecretDetailFeature.State(secret: _previewSecret)
                state.payloadState = .loading
                return state
            }()
        ) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in try await Task.never() }
        }
    )
    .frame(width: 420, height: 700)
}

/// 인증 취소 시나리오. alert를 닫으면 필드 영역 자리에 실패 문구와 재시도 버튼이 남는다 —
/// 이 프리뷰가 확인하려는 지점이다. 헤더는 그대로 남아 즐겨찾기·삭제를 누를 수 있다.
#Preview("SecretDetail · Payload Failed") {
    SecretDetailView(
        store: Store(
            initialState: {
                var state = SecretDetailFeature.State(secret: _previewSecret)
                state.payloadState = .failed(.authenticationFailure(.cancelled))
                return state
            }()
        ) {
            SecretDetailFeature()
        } withDependencies: {
            $0.secretClient.revealPayload = { _ in
                throw SecretUseCaseError.authenticationFailure(.cancelled)
            }
        }
    )
    .frame(width: 420, height: 700)
}

#Preview("SecretDetail · Editing") {
    SecretDetailView(
        store: Store(
            initialState: {
                var state = SecretDetailFeature.State(secret: _previewSecret)
                state.mode = .editing
                return state
            }()
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

#endif
