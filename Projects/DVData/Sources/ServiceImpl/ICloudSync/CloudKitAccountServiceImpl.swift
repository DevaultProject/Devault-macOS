// Copyright © 2026 Devault. All rights reserved

import CloudKit
import DVCore
import DVDomain

public struct CloudKitAccountServiceImpl: ICloudAccountService {

    private let container: CKContainer

    /// - Parameter containerIdentifier: entitlements에 등록된 iCloud 컨테이너 식별자
    public init(containerIdentifier: String) {
        self.container = CKContainer(identifier: containerIdentifier)
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
}
