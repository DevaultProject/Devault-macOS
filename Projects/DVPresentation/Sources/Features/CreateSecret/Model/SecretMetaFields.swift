// Copyright © 2026 Devault. All rights reserved

import DVDomain
import Foundation

/// Create/Edit/Detail 세 화면이 공유하는 폼 VO.
/// Common 필드는 struct 최상위에 두고, type-specific 필드는 `content` enum의 각 case에 담아
/// subType 스위칭 시 case 교체로 이전 subType 값이 자동 clear되도록 한다.
/// SwiftUI 바인딩 편의를 위해 `""`·`nil`·기본 enum을 자유롭게 허용하며,
/// 실제 도메인 진입은 `toCreateSecretPayload`/`toSecretDraft`가 `Result` 반환으로 검증한다.
struct SecretMetaFields: Equatable {
    
    // MARK: - Common Fields
    
    /// 모든 secretType에서 required.
    var name: String = ""
    
    /// 연결할 Project ID 목록. 도메인은 다중을 지원하며, UI가 현재 단일 선택으로 제한(0개 또는 1개)한다.
    var projectIds: [Project.ID] = []
    
    /// 단일 chip. 빈 문자열이면 저장 시 `nil`로 매핑.
    var service: String = ""
    
    /// chip 입력 중인 텍스트. 저장 대상 아닌 순수 UI 상태.
    var servicesInput: String = ""
    
    var expireDate: Date?
    
    /// `SecretDraft.environment`에 `.rawValue`로 저장.
    var environment: SecretEnvironment = .dev
    
    var memo: String = ""
    
    // MARK: - Type-specific
    
    /// (secretType, subType) 조합별 폼 필드. subType 스위칭 시 case 교체로 이전 값 자동 clear.
    var content: SecretContentFields
    
    // MARK: - Init
    
    init(
        content: SecretContentFields,
        name: String = "",
        projectIds: [Project.ID] = [],
        service: String = "",
        servicesInput: String = "",
        expireDate: Date? = nil,
        environment: SecretEnvironment = .dev,
        memo: String = ""
    ) {
        self.content = content
        self.name = name
        self.projectIds = projectIds
        self.service = service
        self.servicesInput = servicesInput
        self.expireDate = expireDate
        self.environment = environment
        self.memo = memo
    }
    
    // MARK: - Field identity
    
    /// 도메인 매핑 실패 시 어느 필드를 지목할지 식별하는 식별자. 검증 대상 필드만 포함.
    enum FieldID: Hashable {
        case name
        case value
        case clientId
        case clientSecret
        case credentialJSON
        case linkString
        case privateKey
        case certificate
        case sslPrivateKey
        case envContent
        case licenseKey
    }
}
