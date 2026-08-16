// Copyright © 2026 Devault. All rights reserved

import DVDomain
import SwiftUI

// MARK: - SecretFormSectionsView

/// `(secretType, subType)` 조합에 대응하는 입력 SectionView를 고르는 디스패처.
///
/// 생성 화면과 수정 화면이 **같은 폼을 쓴다.** 분기가 화면 안에 인라인으로 있으면 SectionView의
/// 시그니처가 바뀔 때마다 두 곳을 따로 고쳐야 하고, 한쪽만 고친 것이 컴파일로도 드러나지 않는다.
///
/// 조회 화면의 `DetailPayloadSectionView`가 표시 섹션에 대해 맡는 역할과 대칭이다.
///
/// TCA store에 결합하지 않고 바인딩·값·콜백만 받는다 — 두 Feature의 State 모양이 다르고,
/// 그래야 SectionView들처럼 독립 프리뷰가 가능하다.
struct SecretFormSectionsView: View {

    // MARK: - Properties

    let secretType: CreatableSecretType
    /// 서브탭이 없는 타입(database · envSet)에서는 `nil`.
    let subType: CreatableSecretSubType?
    @Binding var meta: SecretMetaFields
    let availableProjects: [Project]
    let serviceCandidates: [String]
    let validationErrors: [SecretFieldID: String]
    let detectedServices: [SecretFieldID: String]
    let onCreateProject: () -> Void

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        switch secretType {
        case .apiKeyToken:
            APIKeysTokenSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                environment: $meta.environment,
                memo: $meta.memo,
                apiKeyToken: $meta.content.typed(\.apiKeyToken, default: APIKeyTokenFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .oauth:
            oauthSection

        case .database:
            DatabaseSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                environment: $meta.environment,
                memo: $meta.memo,
                database: $meta.content.typed(\.database, default: DatabaseFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .sshAndCredentials:
            sshAndCredentialsSection

        case .environmentVariableSet:
            EnvSetSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                environment: $meta.environment,
                memo: $meta.memo,
                envSet: $meta.content.typed(\.envSet, default: EnvSetFields()),
                availableProjects: availableProjects,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .etc:
            etcSection
        }
    }
}

// MARK: - Subviews

extension SecretFormSectionsView {

    /// OAuth는 2개 subtype(oauthClient / serviceAccount)이 서로 다른 필드 구성 —
    /// SectionView를 분리하고 subType으로 분기.
    @ViewBuilder
    private var oauthSection: some View {
        switch subType {
        case .oauthClient:
            OAuthClientSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                environment: $meta.environment,
                memo: $meta.memo,
                oauthClient: $meta.content.typed(\.oauthClient, default: OAuthClientFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .serviceAccount:
            ServiceAccountSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                memo: $meta.memo,
                serviceAccount: $meta.content.typed(\.serviceAccount, default: ServiceAccountFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        default:
            EmptyView()
        }
    }

    /// sshAndCredentials는 2개 subtype(sshKey / sslTlsCertificate)이 서로 다른 필드 구성 —
    /// SectionView를 분리하고 subType으로 분기.
    @ViewBuilder
    private var sshAndCredentialsSection: some View {
        switch subType {
        case .sshKey:
            SSHKeySectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                environment: $meta.environment,
                memo: $meta.memo,
                sshKey: $meta.content.typed(\.sshKey, default: SSHKeyFields()),
                availableProjects: availableProjects,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .sslTlsCertificate:
            SSLTLSCertSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                environment: $meta.environment,
                memo: $meta.memo,
                sslCert: $meta.content.typed(\.sslTlsCertificate, default: SSLCertFields()),
                availableProjects: availableProjects,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        default:
            EmptyView()
        }
    }

    /// etc는 2개 subtype(licenseKey / custom)이 서로 다른 필드 구성 —
    /// SectionView를 분리하고 subType으로 분기.
    @ViewBuilder
    private var etcSection: some View {
        switch subType {
        case .licenseKey:
            LicenseKeySectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                memo: $meta.memo,
                licenseKey: $meta.content.typed(\.licenseKey, default: LicenseKeyFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        case .custom:
            CustomSectionView(
                name: $meta.name,
                projectIds: $meta.projectIds,
                service: $meta.service,
                expireDate: $meta.expireDate,
                environment: $meta.environment,
                memo: $meta.memo,
                custom: $meta.content.typed(\.custom, default: CustomFields()),
                availableProjects: availableProjects,
                serviceCandidates: serviceCandidates,
                validationErrors: validationErrors,
                detectedServices: detectedServices,
                onCreateProject: onCreateProject
            )

        default:
            EmptyView()
        }
    }
}
