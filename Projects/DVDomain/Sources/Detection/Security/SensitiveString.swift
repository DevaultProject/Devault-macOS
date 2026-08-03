// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 민감한 문자열 값(시크릿 원문)을 감싸는 래퍼.
///
/// - Raw String은 `withUnsafeAccess(_:)` 클로저 안에서만 접근 가능.
/// - `description` / `debugDescription`은 길이만 노출 → 로깅 사고 차단.
/// - `==` 비교는 constant-time.
/// - 백킹 스토리지는 class(`SensitiveBox`)로 두어 deinit에서 best-effort zero-fill.
public struct SensitiveString: Sendable, Equatable,
    CustomStringConvertible, CustomDebugStringConvertible {

    private let storage: SensitiveBox

    public init(_ value: String) {
        self.storage = SensitiveBox(bytes: Array(value.utf8))
    }

    /// 클로저 스코프에서만 raw 접근 허용. 반환값에 raw String을 담아 밖으로 내보내지 말 것.
    public func withUnsafeAccess<T>(_ body: (String) throws -> T) rethrows -> T {
        try storage.bytes.withUnsafeBufferPointer { buf in
            let raw = String(decoding: buf, as: UTF8.self)
            return try body(raw)
        }
    }

    public var byteCount: Int { storage.bytes.count }

    /// 로그·에러 메시지용 마스킹 프리뷰 (앞 n자만 노출).
    public func redactedPrefix(_ n: Int = 4) -> String {
        withUnsafeAccess { "\($0.prefix(n))*** (len=\($0.count))" }
    }

    public var description: String { "<SensitiveString len=\(byteCount)>" }
    public var debugDescription: String { description }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        SensitiveBox.constantTimeEqual(lhs.storage.bytes, rhs.storage.bytes)
    }
}

/// class로 두어야 deinit에서 zero-fill 가능. 외부 노출 금지.
final class SensitiveBox: @unchecked Sendable {
    var bytes: [UInt8]

    init(bytes: [UInt8]) { self.bytes = bytes }

    deinit {
        // `withUnsafeMutableBufferPointer` 안에서의 쓰기는 pointer 경유라 옵티마이저가 dead store로 제거하기 어렵다.
        // Swift/LLVM 관점에서 완벽한 secure zero는 `memset_s` 등 C API가 필요하지만 DVDomain 스코프 밖.
        bytes.withUnsafeMutableBufferPointer { buffer in
            for i in buffer.indices { buffer[i] = 0 }
        }
    }

    static func constantTimeEqual(_ a: [UInt8], _ b: [UInt8]) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<a.count { diff |= a[i] ^ b[i] }
        return diff == 0
    }
}

#if DEBUG
extension SensitiveString {
    /// 테스트 fixture 편의용. 릴리즈 빌드에는 포함되지 않음.
    public static func testing(_ raw: String) -> SensitiveString {
        SensitiveString(raw)
    }
}
#endif
