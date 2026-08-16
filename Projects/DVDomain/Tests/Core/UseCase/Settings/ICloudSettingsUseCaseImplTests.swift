// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("ICloudSettingsUseCaseImpl")
struct ICloudSettingsUseCaseImplTests {

    @Test("iCloud 동기화 설정과 마지막 동기화 시각을 읽고 쓴다")
    func settingsRoundTrip() async throws {
        let repository = FakeSettingsRepository()
        let sut = ICloudSettingsUseCaseImpl(
            repository: repository,
            iCloudService: StubICloudService(status: .available)
        )
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        try await sut.setEnabled(true)
        sut.setLastSyncedAt(date)

        #expect(sut.isEnabled() == true)
        #expect(sut.lastSyncedAt() == date)
    }

    @Test("iCloud 계정 상태 확인을 Service에 위임한다")
    func accountStatusUsesService() async {
        let sut = ICloudSettingsUseCaseImpl(
            repository: FakeSettingsRepository(),
            iCloudService: StubICloudService(status: .noAccount)
        )

        let status = await sut.accountStatus()

        #expect(status == .noAccount)
    }

    @Test("저장소 구성에 실패하면 설정값을 변경하지 않는다")
    func configurationFailureDoesNotPersistSetting() async {
        let repository = FakeSettingsRepository()
        let sut = ICloudSettingsUseCaseImpl(
            repository: repository,
            iCloudService: StubICloudService(
                status: .available,
                configurationFails: true
            )
        )

        await #expect(throws: StubICloudService.Error.configurationFailed) {
            try await sut.setEnabled(true)
        }
        #expect(repository.isICloudSyncEnabled() == false)
    }

    @Test("iCloud 원격 변경 스트림을 Service에 위임한다")
    func remoteChangeStreamUsesService() async {
        let sut = ICloudSettingsUseCaseImpl(
            repository: FakeSettingsRepository(),
            iCloudService: StubICloudService(
                status: .available,
                emitsRemoteChange: true
            )
        )

        var iterator = sut.remoteChangeStream().makeAsyncIterator()
        let value = await iterator.next()

        #expect(value != nil)
    }
}

private struct StubICloudService: ICloudService {
    enum Error: Swift.Error {
        case configurationFailed
    }

    let status: ICloudAccountStatus
    var emitsRemoteChange = false
    var configurationFails = false

    func fetchAccountStatus() async -> ICloudAccountStatus {
        status
    }

    func remoteChangeStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            if emitsRemoteChange {
                continuation.yield(())
            }
            continuation.finish()
        }
    }

    func configureStorage(iCloudSyncEnabled: Bool) async throws {
        if configurationFails {
            throw Error.configurationFailed
        }
    }
}
