// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign
import DVDomain

/// 시크릿 조회 화면 상단 헤더 — 즐겨찾기 + 타입명 + 액션 + 읽기 전용 서브타입 탭바.
///
/// Figma `1768:30819` (Header, 380×62) 구현.
///
/// ```
/// [★ API Keys/Token                        ↗  ✎  🗑]   ← Type row, 30pt
///                                                        ← spacing 16
/// [○ API Key   ● Access Token   ○ API Webhook Secret]   ← Tab Bar, 16pt
/// ```
///
/// 생성 화면의 `CreateSecretHeaderView`에 대응하지만 두 가지가 다르다:
/// 1. 액션(즐겨찾기·공유·수정·삭제)이 타입 행에 함께 놓인다.
/// 2. **서브타입 탭바는 읽기 전용이다** — `DVRadioButton(readOnly:isSelected:)`.
///
/// 서브타입은 조회·수정 모드 모두에서 변경할 수 없다. 서브타입이 바뀌면 payload 스키마
/// 자체가 달라지므로(`CreateSecretPayload` case가 교체됨) 기존 시크릿의 서브타입 변경은
/// 수정이 아니라 재생성에 해당한다.
///
/// TCA store에 결합하지 않고 값·콜백만 받아 독립 Preview가 가능하다.
struct SecretDetailHeaderView: View {

    let secretType: SecretType
    let subType: SecretSubType?
    let isLiked: Bool
    /// payload 복호화 전/실패 상태에서는 수정 진입을 막는다.
    /// `isEditing`이 참이면 수정 버튼 자체가 렌더되지 않으므로 조회 모드에서만 의미가 있다.
    var isEditEnabled: Bool = true
    /// 편집 폼 위에 얹힌 헤더인지.
    ///
    /// 편집 중에는 **공유·수정·삭제를 렌더하지 않는다.** 눌러도 반응하지 않는 컨트롤을 노출하지
    /// 않는다는 기준을 따르고(`#74`에서 수정 버튼을 숨긴 것과 같다), 편집 중 유효한 동작은
    /// footer의 Save / Cancel뿐이다.
    ///
    /// **즐겨찾기만 남긴다.** 별은 액션이면서 동시에 상태 표시라, 숨기면 이 시크릿이 즐겨찾기인지가
    /// 화면에서 사라진다. 대신 회색으로 바꿔 지금은 바꿀 수 없다는 것을 알린다 — 즐겨찾기 변경은
    /// 조회 모드에서만 가능하다는 것이 정책이다. 편집 중에 즐겨찾기가 성공하면 `state.secret`이
    /// 교체되어 저장 diff의 기준인 baseline과 어긋난다.
    var isEditing: Bool = false
    let onToggleLike: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var subTypes: [CreatableSecretSubType] {
        secretType.creatableType.availableSubTypes
    }

    /// `subType`이 nil일 때의 폴백은 `resolvedSubType`이 정의한다 — 저장 경로와 같은 규칙을 써야
    /// 화면에 보이는 서브타입과 저장되는 서브타입이 갈리지 않는다.
    private var selectedSubType: CreatableSecretSubType? {
        secretType.creatableType.resolvedSubType(subType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: subTypes.isEmpty ? 0 : 16) {
            typeRow
            if !subTypes.isEmpty {
                tabBar
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Subviews

extension SecretDetailHeaderView {

    private var typeRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                likeButton
                Text(secretType.creatableType.displayName)
                    .dvFont(.headingXL)
                    .foregroundStyle(Color.dv(.gray900))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if !isEditing {
                actionsContainer
            }
        }
        // 액션이 빠져도 행 높이가 흔들리지 않도록 고정한다 — 모드 전환 시 타입명이 위아래로 움직이면 안 된다.
        .frame(height: 30)
    }

    private var likeButton: some View {
        Button(action: onToggleLike) {
            Image(systemName: isLiked ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                // 색으로 비활성을 알린다. 별은 원래 유채색이라 opacity만 낮추면
                // "연한 초록"이 되어 꺼진 것으로 읽히지 않는다.
                .foregroundStyle(Color.dv(isEditing ? .gray400 : .vaultGreen))
                .frame(width: 24, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isEditing)
        .accessibilityLabel(
            Text(isLiked ? .module("Remove from favorites") : .module("Add to favorites"))
        )
    }

    private var actionsContainer: some View {
        HStack(spacing: 6) {
            // 공유 동작은 아직 정해지지 않았다. 눌러도 반응하지 않는 컨트롤을 활성 상태로
            // 노출하지 않기 위해 disabled로 렌더한다.
            actionButton(
                systemName: "square.and.arrow.up",
                accessibilityLabel: .module("Share"),
                isEnabled: false,
                action: {}
            )
            actionButton(
                systemName: "pencil",
                accessibilityLabel: .module("Edit"),
                isEnabled: isEditEnabled,
                action: onEdit
            )
            actionButton(
                systemName: "trash",
                accessibilityLabel: .module("Delete"),
                action: onDelete
            )
        }
    }

    private func actionButton(
        systemName: String,
        accessibilityLabel: LocalizedStringResource,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.dv(.gray900))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        // .plain 버튼은 disabled에서 자동으로 흐려지지 않으므로 명시적으로 낮춘다.
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var tabBar: some View {
        // Figma 시각 간격은 28pt. DVRadioButton이 좌우 2pt 패딩을 가지므로
        // HStack spacing은 28 - (2 + 2) = 24로 두어야 실제 간격이 28이 된다.
        HStack(spacing: 24) {
            ForEach(subTypes, id: \.self) { sub in
                DVRadioButton(
                    readOnly: String(localized: sub.displayName),
                    isSelected: sub == selectedSubType
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG

/// Figma 기준 폭 — Main Container 420 - 좌우 padding 20×2.
private let _headerWidth: CGFloat = 380

#Preview("API Keys/Token · Access Token 선택") {
    SecretDetailHeaderView(
        secretType: .apiKeyToken,
        subType: .accessToken,
        isLiked: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("API Keys/Token · liked") {
    SecretDetailHeaderView(
        secretType: .apiKeyToken,
        subType: .apiKey,
        isLiked: true,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("OAuth · 2 subs") {
    SecretDetailHeaderView(
        secretType: .oauth,
        subType: .serviceAccount,
        isLiked: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("SSH & Credentials · 긴 타입명") {
    SecretDetailHeaderView(
        secretType: .sshAndCredentials,
        subType: .sslTlsCertificate,
        isLiked: true,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("Database · 탭바 없음") {
    SecretDetailHeaderView(
        secretType: .database,
        subType: nil,
        isLiked: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("EnvSet · 탭바 없음") {
    SecretDetailHeaderView(
        secretType: .environmentVariableSet,
        subType: nil,
        isLiked: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("ETC · subType nil → 첫 탭 선택") {
    SecretDetailHeaderView(
        secretType: .etc,
        subType: nil,
        isLiked: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

/// 편집 중 모습. 공유·수정·삭제는 사라지고 즐겨찾기만 회색으로 남는다 —
/// 즐겨찾기 여부는 계속 보여야 하는 정보이고, 회색이 지금은 바꿀 수 없다는 표시다.
/// 액션이 빠져도 타입명 행의 높이는 조회 모드와 같아야 한다.
#Preview("편집 중 · 즐겨찾기만 회색으로 남음") {
    SecretDetailHeaderView(
        secretType: .apiKeyToken,
        subType: .apiKey,
        isLiked: true,
        isEditing: true,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#Preview("수정 비활성 (payload 미복호화)") {
    SecretDetailHeaderView(
        secretType: .apiKeyToken,
        subType: .apiKey,
        isLiked: false,
        isEditEnabled: false,
        onToggleLike: {},
        onEdit: {},
        onDelete: {}
    )
    .padding(20)
    .previewWidth(_headerWidth + 40)
}

#endif
