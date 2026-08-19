// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

import DVCore
import DVDomain

@testable import DVData

/// 목록에 **보이는** 날짜로 검색이 되는지 본다. 표시와 매칭이 서로 다른 코드를 타므로
/// 둘이 계속 맞물리는지 확인이 필요하다.
///
/// 검색어는 전부 `displayString`에서 유도한다 — 문자열을 박으면 실행 로케일이 바뀔 때 깨진다.
@Suite("Secret 날짜 검색")
struct SecretDateSearchTests {

    /// 로컬 정오로 고정한다 — 자정을 쓰면 기기 시간대에 따라 날짜가 하루 밀린다.
    private static let updatedAt = Self.localNoon(year: 2026, month: 4, day: 1)

    /// 표시되는 `updatedAt`과 다른 날로 둔다 — 한쪽 단언이 다른 쪽 날짜에 우연히 걸려
    /// 통과하는 것을 막는다.
    private static let createdAt = Self.localNoon(year: 2025, month: 12, day: 25)

    // MARK: - 보이는 날짜로 검색

    @Test("목록에 보이는 날짜 문자열 그대로 검색하면 걸린다")
    func searchByDisplayedDate() {
        let secret = Self.makeSecret()

        #expect(Self.search(Self.displayed(Self.updatedAt), in: [secret]) == [secret.id])
    }

    /// 로케일 숫자 날짜에는 공백이 섞인다(ko `2026. 4. 1.`). 사용자가 공백까지 맞춰 칠
    /// 것을 기대할 수 없으므로 공백을 뗀 표기도 걸려야 한다.
    @Test("보이는 날짜에서 공백을 뺀 표기로도 걸린다")
    func searchByDisplayedDateWithoutWhitespace() {
        let secret = Self.makeSecret()
        let compact = Self.displayed(Self.updatedAt).filter { !$0.isWhitespace }

        #expect(Self.search(compact, in: [secret]) == [secret.id])
    }

    // MARK: - 검색 대상 범위

    /// `createdAt`은 목록에 표시되지 않지만 검색 대상으로는 남아 있다.
    @Test("표시되지 않는 createdAt으로도 걸린다")
    func searchByCreatedAt() {
        let secret = Self.makeSecret()

        #expect(Self.search(Self.displayed(Self.createdAt), in: [secret]) == [secret.id])
    }

    @Test("어느 날짜와도 맞지 않으면 걸리지 않는다")
    func searchByOtherDateDoesNotMatch() {
        let secret = Self.makeSecret()
        let otherDay = Self.displayed(Self.localNoon(year: 2026, month: 4, day: 2))

        #expect(Self.search(otherDay, in: [secret]).isEmpty)
    }

    /// 날짜 매칭이 검색어의 공백을 떼는 탓에 텍스트 필드까지 느슨해지면 안 된다 —
    /// 이름 검색은 공백을 그대로 본다.
    @Test("텍스트 필드는 공백을 무시하지 않는다")
    func textFieldMatchingKeepsWhitespace() {
        let secret = Self.makeSecret(name: "My Token")

        #expect(Self.search("My Token", in: [secret]) == [secret.id])
        #expect(Self.search("MyToken", in: [secret]).isEmpty)
    }
}

// MARK: - Support

private extension SecretDateSearchTests {

    static func localNoon(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: .current, year: year, month: month, day: day, hour: 12).date!
    }

    static func displayed(_ date: Date) -> String {
        SecretDateFormatter.displayString(from: date)
    }

    static func search(_ keyword: String, in secrets: [DVDomain.Secret]) -> [UUID] {
        InMemorySecretQueryFilter
            .apply(SecretQuery(searchText: keyword), to: secrets)
            .map(\.id)
    }

    /// 기본 이름에 숫자가 없어야 날짜 단언이 이름에 걸려 통과하는 일이 없다.
    static func makeSecret(name: String = "Token") -> DVDomain.Secret {
        DVDomain.Secret(
            id: UUID(),
            name: name,
            secretType: .apiKeyToken,
            createdAt: createdAt,
            updatedAt: updatedAt,
            payload: SecretPayload(encryptedData: Data(), keyTag: "test", schemaVersion: 1)
        )
    }
}
