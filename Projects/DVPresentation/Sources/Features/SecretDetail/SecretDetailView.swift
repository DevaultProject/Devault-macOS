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
                        viewingBody(layout: layout)
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

    /// 헤더 + 공통 메타 필드까지 구현된 상태다. 후속 작업에서 `store.payloadState`의
    /// loading / failed 분기와 타입별 payload 섹션(`primary` / `trailing` 슬롯)을 채운다.
    /// `layout`을 파라미터로 받는다 — `@Environment`로 읽으면 이 뷰가 `formLayout(_:)`으로
    /// 주입한 값이 아니라 상위 환경 값을 보게 된다.
    @ViewBuilder
    private func viewingBody(layout: FormLayout) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                // 공통 메타 필드는 payload 복호화와 무관하게 `Secret`에서 바로 나오므로
                // `payloadState`를 기다리지 않고 그린다.
                DetailSectionScaffoldView(
                    secret: store.secret,
                    linkedProjects: store.linkedProjects
                )
            }
            .padding(.horizontal, FormLayoutMetrics.horizontalPadding)
            .padding(.vertical, FormLayoutMetrics.horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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

private let _previewSecret = Secret(
    id: UUID(),
    name: "GitHub Personal Token",
    secretType: .apiKeyToken,
    service: "GitHub",
    environment: "production",
    createdAt: Date(),
    updatedAt: Date(),
    payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
)

#Preview("SecretDetail · Viewing") {
    SecretDetailView(
        store: Store(
            initialState: SecretDetailFeature.State(secret: _previewSecret)
        ) {
            SecretDetailFeature()
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
