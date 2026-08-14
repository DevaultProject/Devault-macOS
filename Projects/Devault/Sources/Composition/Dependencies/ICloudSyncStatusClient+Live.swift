// Copyright © 2026 Devault. All rights reserved

import CoreData
import Foundation

import ComposableArchitecture
import DVCore
import DVData
import DVDomain
import DVPresentation

extension ICloudSyncStatusClient: @retroactive DependencyKey {
  public static let liveValue: ICloudSyncStatusClient = {
    let iCloudSyncSettings: any ICloudSyncSettingsUseCase = ICloudSyncSettingsUseCaseImpl(
      repository: LiveRepositories.settings
    )
    let accountService: any ICloudAccountService = CloudKitAccountServiceImpl(
      containerIdentifier: ICloudContainer.identifier
    )

    return ICloudSyncStatusClient(
      lastSyncedAt: {
        iCloudSyncSettings.lastSyncedAt()
      },
      setLastSyncedAt: { date in
        iCloudSyncSettings.setLastSyncedAt(date)
      },
      remoteChangeStream: {
        AsyncStream { continuation in
          // SwiftData+CloudKit도 내부적으로 Core Data 스택이라, 원격 변경 시 시스템 전역으로
          // 이 알림이 posting된다 — SwiftData가 별도로 감추지 않는다.
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
      },
      accountStatus: {
        await accountService.fetchAccountStatus()
      },
      syncedSecretCount: {
        try await LiveRepositories.secret.count(SecretQuery(collection: .all))
      },
      syncedProjectCount: {
        try await LiveRepositories.project.fetchAll().count
      }
    )
  }()
}
