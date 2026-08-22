// Copyright © 2026 Devault. All rights reserved

public struct EntitlementUseCaseImpl: EntitlementUseCase {

    private let secretRepository: any SecretRepository
    private let projectRepository: any ProjectRepository
    private let entitlementProvider: @Sendable () -> Entitlement
    private let entitlementStream: @Sendable () -> AsyncStream<Entitlement>

    /// 등급 공급자를 주입받아 생성한다.
    ///
    /// StoreKit이 붙기 전에는 Composition Root가 `.free`를 고정으로 넘기고, 붙은 뒤에는 `PurchaseService`가 넘긴다. **판정 로직은 그대로 두고 근거만 교체**하기 위한 구조이며, 테스트에서 `.pro`를 주입하는 통로이기도 하다.
    /// - Parameters:
    ///   - secretRepository: Secret 개수 판정에 쓰는 저장소
    ///   - projectRepository: Project 개수 판정에 쓰는 저장소
    ///   - entitlementProvider: 현재 등급을 돌려주는 클로저
    ///   - entitlementStream: 등급 변경 스트림을 만드는 클로저
    public init(
        secretRepository: any SecretRepository,
        projectRepository: any ProjectRepository,
        entitlementProvider: @escaping @Sendable () -> Entitlement,
        entitlementStream: @escaping @Sendable () -> AsyncStream<Entitlement>
    ) {
        self.secretRepository = secretRepository
        self.projectRepository = projectRepository
        self.entitlementProvider = entitlementProvider
        self.entitlementStream = entitlementStream
    }

    public func current() -> Entitlement {
        entitlementProvider()
    }

    public func stream() -> AsyncStream<Entitlement> {
        entitlementStream()
    }

    public func canCreateSecret() async throws -> Bool {
        guard current() == .free else { return true }
        return try await secretRepository.totalCountExcludingTrash() < EntitlementLimits.maxSecrets
    }

    public func canCreateProject() async throws -> Bool {
        guard current() == .free else { return true }
        // Project는 무료 1개 · Pro 무제한이라 목록이 길어질 일이 없다. 전용 count를 두지 않는다.
        return try await projectRepository.fetchAll().count < EntitlementLimits.maxProjects
    }

    public func canEditSecrets() async throws -> Bool {
        guard current() == .free else { return true }
        // 한도와 **같으면** 허용한다. `canCreateSecret`의 `<`와 달리 여기가 `<=`인 이유는, 정확히 한도만큼 보유한 사용자는 잠기면 안 되기 때문이다. 잠금은 초과부터다.
        return try await secretRepository.totalCountExcludingTrash() <= EntitlementLimits.maxSecrets
    }

    public func canEnableICloudSync() -> Bool {
        current() == .pro
    }

    public func canUseMultipleExpiryAlertDays() -> Bool {
        current() == .pro
    }
}
