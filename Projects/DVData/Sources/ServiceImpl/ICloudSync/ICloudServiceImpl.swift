// Copyright © 2026 Devault. All rights reserved

import CloudKit
import CoreData
import Foundation

import DVCore
import DVDomain

public struct ICloudServiceImpl: ICloudService {

    private let container: CKContainer
    private let storageConfigurator: @Sendable (Bool) async throws -> Void

    public init(
        containerIdentifier: String,
        storageConfigurator: @escaping @Sendable (Bool) async throws -> Void
    ) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.storageConfigurator = storageConfigurator
    }

    public func fetchAccountStatus() async -> ICloudAccountStatus {
        do {
            switch try await container.accountStatus() {
            case .available:
                return .available
            case .noAccount:
                return .noAccount
            case .restricted:
                return .restricted
            case .temporarilyUnavailable:
                return .temporarilyUnavailable
            case .couldNotDetermine:
                return .couldNotDetermine
            @unknown default:
                return .couldNotDetermine
            }
        } catch let error as CKError {
            switch error.code {
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable
            case .notAuthenticated:
                return .noAccount
            case .badContainer, .missingEntitlement:
                // container identifier 오타나 entitlement 누락 등 배포 설정 문제. 재시도로는 해결되지 않으므로 로그 추가
                Log.error("iCloud 컨테이너 설정 오류: \(error)", category: .security)
                return .configurationUnavailable
            default:
                return .couldNotDetermine
            }
        } catch {
            return .couldNotDetermine
        }
    }

    public func remoteChangeStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            // SwiftData+CloudKit도 내부적으로 Core Data 스택을 사용하므로 원격 변경 시
            // NSPersistentStoreRemoteChange가 시스템 NotificationCenter에 게시된다.
            let observer = NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: nil,
                queue: nil
            ) { _ in
                continuation.yield(())
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    public func configureStorage(iCloudSyncEnabled: Bool) async throws {
        try await storageConfigurator(iCloudSyncEnabled)
    }
}
