// Copyright © 2026 Devault. All rights reserved

import CloudKit
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
            default:
                return .couldNotDetermine
            }
        } catch {
            return .couldNotDetermine
        }
    }
}
