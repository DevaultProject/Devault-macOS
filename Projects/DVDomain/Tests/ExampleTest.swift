import Testing
@testable import DVDomain

@Suite("Example")
struct ExampleTest {
    @Test("조건을 만족해야 한다")
    func example() {
        #expect(1 + 1 == 2)
    }
}
