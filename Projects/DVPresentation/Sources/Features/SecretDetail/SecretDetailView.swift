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
        // `finish()`를 await해야 secret이 바뀔 때 이전 secret의 lifecycle 구독과 프로젝트 조회가
        // 함께 끝난다. 눈·복사는 이 task의 자식이 아니므로 여기서 취소되지 않는다 —
        // 그쪽은 `State.id`를 보고 `ifLet`이 취소한다.
        .task(id: store.secret.id) {
            await store.send(.task).finish()
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

extension SecretDetailView {

    // MARK: Viewing

    /// 복호화 여부와 무관하게 항상 같은 섹션을 렌더한다. payload 필드는 값이 있든 없든 마스킹되므로
    /// 복호화 전후로 화면 구성이 달라지지 않고, 로딩·실패 전용 화면도 필요 없다(실패는 alert로 알린다).
    ///
    /// 눈·복사 동작은 Environment로 내려보낸다 — 필드가 9개 섹션 안쪽에 흩어져 있어
    /// 파라미터로 넘기면 중간 섹션들이 쓰지도 않는 값을 계속 실어 나른다.
    private var viewingBody: some View {
        ScrollView {
            bodyStack {
                DetailPayloadSectionView(
                    secret: store.secret,
                    linkedProjects: store.linkedProjects,
                    payload: displayedPayload
                )
            }
        }
        .environment(
            \.detailFieldActions,
            DetailFieldActions(
                revealedFields: store.revealedFields,
                onToggleReveal: { store.send(.didTapToggleReveal($0)) },
                onCopy: { store.send(.didTapCopy($0)) },
                onCopyPlainValue: { store.send(.didTapCopyPlainValue($0)) }
            )
        )
    }

    /// reveal 전에는 payload만 빈 껍데기를 넘긴다. 민감 필드는 어차피 마스킹되어 화면이 같고,
    /// metadata는 평문이라 `Secret`에서 그대로 채워지므로 평문 필드가 처음부터 보인다.
    private var displayedPayload: CreateSecretPayload {
        if case .loaded(let payload) = store.payloadState {
            return payload
        }
        return .beforeReveal(for: store.secret)
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

/// reveal까지 끝난 모습. 진입만으로는 이 상태에 도달하지 않으므로 State를 직접 세팅한다 —
/// 마스킹이 풀린 필드와 그대로 가려진 필드가 한 화면에 같이 보이는 것이 확인 대상이다.
#Preview("SecretDetail · reveal 후") {
    SecretDetailView(
        store: Store(
            initialState: {
                var state = SecretDetailFeature.State(secret: _previewSecret)
                state.payloadState = .loaded(
                    .apiKey(APIKeyPayload(value: "ghp_preview_token"), APIKeyMetadata(scope: "repo:read"))
                )
                state.revealedFields = [.value]
                return state
            }()
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

/// 진입 직후 모습 — 복호화하지 않으므로 payload 필드가 전부 마스킹된 채로 그려진다.
/// 평문 필드(Services·Environment 등)는 `Secret`에서 오므로 값이 그대로 보여야 한다.
#Preview("SecretDetail · 복호화 전") {
    SecretDetailView(
        store: Store(
            initialState: SecretDetailFeature.State(secret: _previewSecret)
        ) {
            SecretDetailFeature()
        }
    )
    .frame(width: 420, height: 700)
}

/// 인증 취소 시나리오. 실패는 alert로만 알리고 필드는 마스킹된 채 남는다 —
/// 화면 전체를 덮는 실패 뷰가 없다는 것이 이 프리뷰가 확인하려는 지점이다.
#Preview("SecretDetail · 인증 취소") {
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
