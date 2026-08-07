// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain

/// Composition Root 전체에서 공유하는 Repository 인스턴스.
/// SwiftData @ModelActor는 modelContainer를 공유하므로 동일 actor 인스턴스를 사용해야
/// in-memory 트랜잭션 격리가 일관되게 유지된다.
enum LiveRepositories {
    static let secret: any SecretRepository = SecretRepositoryImpl(
        modelContainer: LiveStorage.shared.modelContainer
    )
    static let project: any ProjectRepository = ProjectRepositoryImpl(
        modelContainer: LiveStorage.shared.modelContainer
    )
}
