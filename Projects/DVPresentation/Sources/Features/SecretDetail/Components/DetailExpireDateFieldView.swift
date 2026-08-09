// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDesign
import DVDomain

/// 조회 화면의 Expire Date 필드 — 만료가 임박하면 박스 안 `아이콘 + 날짜`를 같은 색으로 강조한다.
///
/// 강조가 없을 때의 모습은 `DetailReadOnlyFieldView`의 plain 상태와 같다. 그래도 별도 뷰로 둔 것은
/// 만료 판정(`SecretExpiryStatus`)을 아는 필드가 이 하나뿐이기 때문이다 —
/// 읽기 전용 필드 일반에 만료라는 도메인 개념을 심지 않는다.
///
/// 만료일이 없으면 강조도 없고 값도 빈 문자열이라 다른 optional 필드와 같은 Empty 상태로 남는다.
struct DetailExpireDateFieldView: View {

    let secret: Secret
    var sizeMode: FormSlotSize = .paired

    @Environment(\.formLayout) private var layout

    private var size: DVComponentSize {
        layout.size(for: sizeMode)
    }

    private var emphasis: DVExpiryEmphasis? {
        SecretExpiryStatus(expiresAt: secret.expiresAt)?.emphasis
    }

    var body: some View {
        DVLabeledField(.module("Expire Date"), size: size) {
            DVTextContainer(
                secret.expireDateDisplayText,
                size: size,
                textColor: emphasis?.colorToken ?? .gray900,
                leadingIcon: emphasis?.icon
            )
        }
    }
}

// MARK: - Preview

#if DEBUG

private func _secret(expiresAt: Date?) -> Secret {
    Secret(
        id: UUID(),
        name: "Preview",
        secretType: .apiKeyToken,
        expiresAt: expiresAt,
        createdAt: .now,
        updatedAt: .now,
        payload: SecretPayload(encryptedData: Data(), keyTag: "preview", schemaVersion: 1)
    )
}

#Preview("만료 임박 4단계 · paired") {
    VStack(alignment: .leading, spacing: 16) {
        DetailExpireDateFieldView(secret: _secret(expiresAt: .now.addingTimeInterval(-5 * 86_400)))
        DetailExpireDateFieldView(secret: _secret(expiresAt: .now.addingTimeInterval(2 * 86_400)))
        DetailExpireDateFieldView(secret: _secret(expiresAt: .now.addingTimeInterval(5 * 86_400)))
        DetailExpireDateFieldView(secret: _secret(expiresAt: .now.addingTimeInterval(30 * 86_400)))
    }
    .padding()
    .formLayout(.detailFluid)
    .previewWidth(420)
}

/// 만료일이 없으면 Empty 상태 — 아이콘도 강조색도 붙지 않는다.
#Preview("만료일 없음") {
    DetailExpireDateFieldView(secret: _secret(expiresAt: nil))
        .padding()
        .formLayout(.detailFluid)
        .previewWidth(420)
}

#Preview("dual") {
    AdaptiveFieldRow {
        DetailExpireDateFieldView(secret: _secret(expiresAt: .now.addingTimeInterval(86_400)))
    } right: {
        DetailReadOnlyFieldView(
            label: .module("Environment"),
            value: "production",
            sizeMode: .paired
        )
    }
    .padding()
    .formLayout(.dual)
    .previewWidth(.wide)
}

#endif
