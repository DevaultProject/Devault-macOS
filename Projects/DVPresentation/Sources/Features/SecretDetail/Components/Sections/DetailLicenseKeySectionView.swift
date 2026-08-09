// Copyright © 2026 Devault. All rights reserved

import SwiftUI

import DVDomain

/// `etc`의 `.licenseKey` 서브타입 조회 섹션 — 생성 화면 `LicenseKeySectionView`의 read-only 대응.
///
/// 생성 화면과 같이 Environment 자리를 License Tier("Type")가 차지한다.
struct DetailLicenseKeySectionView: View {

    let secret: Secret
    let linkedProjects: [Project]
    let payload: LicenseKeyPayload
    /// 생성 폼의 "Type" / "Support Email" / "Website" / "Order Number" 입력이 `LicenseKeyMetadata`로 저장된다.
    let metadata: LicenseKeyMetadata?

    var body: some View {
        DetailSectionScaffoldView(secret: secret) {
            DetailReadOnlyFieldView(
                label: .module("License Key"),
                value: payload.licenseKey,
                isSensitive: true,
                isCopyable: true
            )

            AdaptiveFieldRow {
                DetailProjectFieldView(projects: linkedProjects)
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Services"),
                    value: secret.serviceDisplayText,
                    sizeMode: .paired
                )
            }

            AdaptiveFieldRow {
                DetailExpireDateFieldView(secret: secret)
            } right: {
                DetailReadOnlyFieldView(
                    label: .module("Type"),
                    value: licenseTierDisplayText,
                    sizeMode: .paired
                )
            }

            DetailReadOnlyFieldView(
                label: .module("Support Email"),
                value: metadata?.registrationEmail ?? ""
            )

            DetailReadOnlyFieldView(
                label: .module("Website"),
                value: metadata?.website ?? ""
            )

            DetailReadOnlyFieldView(
                label: .module("Order Number"),
                value: metadata?.orderNumber ?? ""
            )
        }
    }

    /// 생성 폼이 `LicenseTier.rawValue`로 저장한 값을 표시명으로 되돌린다.
    /// 매핑되지 않는 값이면 원문을 그대로 보여준다 — 조회 화면이 값을 숨기면 안 된다
    /// (`Secret.environmentDisplayText`와 같은 규칙).
    private var licenseTierDisplayText: String {
        guard let licenseType = metadata?.licenseType else { return "" }
        guard let tier = LicenseTier(rawValue: licenseType) else { return licenseType }
        return String(localized: tier.displayName)
    }
}

// MARK: - Preview

#if DEBUG

#Preview("licenseKey · matrix[9] (420)") {
    ScrollView {
        DetailLicenseKeySectionView(
            secret: [Secret].previewSubTypeMatrix[9],
            linkedProjects: [Project].preview,
            payload: LicenseKeyPayload(licenseKey: "XXXXX-XXXXX-XXXXX-XXXXX"),
            metadata: LicenseKeyMetadata(
                licenseType: LicenseTier.team.rawValue,
                registrationEmail: "support@example.com",
                orderNumber: "DV-2026-000123",
                website: "https://example.com"
            )
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

/// `LicenseTier`로 매핑되지 않는 `licenseType`은 원문 그대로 노출된다.
#Preview("licenseKey · 미지의 tier · matrix[9]") {
    ScrollView {
        DetailLicenseKeySectionView(
            secret: [Secret].previewSubTypeMatrix[9],
            linkedProjects: [Project].preview,
            payload: LicenseKeyPayload(licenseKey: "XXXXX-XXXXX-XXXXX-XXXXX"),
            metadata: LicenseKeyMetadata(licenseType: "campus")
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#Preview("licenseKey · 값 비어있음 · matrix[9]") {
    ScrollView {
        DetailLicenseKeySectionView(
            secret: [Secret].previewSubTypeMatrix[9],
            linkedProjects: [],
            payload: LicenseKeyPayload(licenseKey: ""),
            metadata: nil
        )
        .padding(20)
    }
    .formLayout(.detailFluid)
    .previewWidth(420)
}

#endif
