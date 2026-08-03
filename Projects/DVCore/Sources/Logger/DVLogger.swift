// Copyright © 2026 Devault. All rights reserved

import Foundation
import OSLog

/// OSLog `category` 값. Console.app 필터링 축으로 쓰인다.
public enum LogCategory: String, Sendable {
    case general, ui, data, storage, network, security, crypto, domain
}

/// 앱 전역 로거의 네임스페이스 프로토콜.
///
/// enum 하나를 conform 시켜 로거를 만든다. 대부분은 DVCore 가 제공하는 ``Log`` 를 그대로 쓴다.
///
/// ```swift
/// import DVCore
///
/// Log.debug("보관함 로드 완료")
/// Log.error("저장 실패", category: .storage)
/// // 콘솔: 🔴 [VaultView.swift:42] loadVault() - 저장 실패
/// ```
///
/// 파일명·라인·함수는 자동으로 붙으므로 메시지만 넘기면 된다.
///
/// ## 모듈 전용 로거
///
/// 특정 모듈을 별도 subsystem 으로 분리하려면 한 줄이면 된다. 메서드는 전부 상속된다.
///
/// ```swift
/// enum Log: DVLogger { static let subsystem = "com.devault.network" }
/// ```
///
/// ## 실행 시간 측정
///
/// ```swift
/// let secret = try await Log.measure("복호화") {
///     try await cryptoService.decrypt(payload)
/// }
/// // ⏱ [CryptoService.swift:88] decrypt() - 복호화 - 12.34ms
/// ```
///
/// ## 레벨과 빌드
///
/// - `debug` / `info` / `warn`: Debug 빌드 전용. Release 에선 no-op(문자열 평가조차 안 함).
/// - `error` / `critical`: 항상 기록. Release 에선 메시지를 해시 마스킹한다.
///
/// - Important: 시크릿 값 자체를 메시지에 넣지 말 것. Release 마스킹은 최후 방어선일 뿐이다.
public protocol DVLogger {
    /// OSLog subsystem (역DNS 권장).
    static var subsystem: String { get }
    /// 카테고리 미지정 시 기본값. 기본 구현은 `.general`.
    static var defaultCategory: LogCategory { get }
}

extension DVLogger {
    public static var defaultCategory: LogCategory { .general }
}

// MARK: - Level Methods

extension DVLogger {
    /// 상세 디버그 로그. Debug 빌드 전용.
    public static func debug(_ message: @autoclosure () -> String, category: LogCategory? = nil,
                      file: String = #fileID, function: String = #function, line: Int = #line) {
        #if DEBUG
        emit(.debug, "⚪️", message(), category ?? defaultCategory, file, function, line)
        #endif
    }

    /// 일반 정보 로그. Debug 빌드 전용.
    public static func info(_ message: @autoclosure () -> String, category: LogCategory? = nil,
                     file: String = #fileID, function: String = #function, line: Int = #line) {
        #if DEBUG
        emit(.info, "🔵", message(), category ?? defaultCategory, file, function, line)
        #endif
    }

    /// 경고 로그. Debug 빌드 전용.
    public static func warn(_ message: @autoclosure () -> String, category: LogCategory? = nil,
                     file: String = #fileID, function: String = #function, line: Int = #line) {
        #if DEBUG
        emit(.default, "🟡", message(), category ?? defaultCategory, file, function, line)
        #endif
    }

    /// 에러 로그. 항상 기록되며 Release 에선 마스킹된다.
    public static func error(_ message: @autoclosure () -> String, category: LogCategory? = nil,
                      file: String = #fileID, function: String = #function, line: Int = #line) {
        emit(.error, "🔴", message(), category ?? defaultCategory, file, function, line)
    }

    /// 치명적 에러 로그. 항상 기록되며 Release 에선 마스킹된다.
    public static func critical(_ message: @autoclosure () -> String, category: LogCategory? = nil,
                         file: String = #fileID, function: String = #function, line: Int = #line) {
        emit(.fault, "🟣", message(), category ?? defaultCategory, file, function, line)
    }
}

// MARK: - measure

extension DVLogger {
    /// 동기 블록의 실행 시간을 `⏱ … - 12.34ms` 로 로깅한다. Release 에선 측정 없이 실행만 한다.
    @discardableResult
    public static func measure<T>(_ label: String, category: LogCategory? = nil,
                           file: String = #fileID, function: String = #function, line: Int = #line,
                           _ work: () throws -> T) rethrows -> T {
        #if DEBUG
        let start = ContinuousClock().now
        defer {
            let ms = start.duration(to: ContinuousClock().now).milliseconds
            emit(.debug, "⏱", "\(label) - \(String(format: "%.2f", ms))ms",
                 category ?? defaultCategory, file, function, line)
        }
        #endif
        return try work()
    }

    /// ``measure(_:category:file:function:line:_:)`` 의 async 버전.
    @discardableResult
    public static func measure<T>(_ label: String, category: LogCategory? = nil,
                           file: String = #fileID, function: String = #function, line: Int = #line,
                           _ work: () async throws -> T) async rethrows -> T {
        #if DEBUG
        let start = ContinuousClock().now
        defer {
            let ms = start.duration(to: ContinuousClock().now).milliseconds
            emit(.debug, "⏱", "\(label) - \(String(format: "%.2f", ms))ms",
                 category ?? defaultCategory, file, function, line)
        }
        #endif
        return try await work()
    }
}

// MARK: - Pipeline

private extension DVLogger {
    static func emit(_ type: OSLogType, _ symbol: String, _ message: @autoclosure () -> String,
                     _ category: LogCategory, _ file: String, _ function: String, _ line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let text = "\(symbol) [\(fileName):\(line)] \(function) - \(message())"
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        #if DEBUG
        logger.log(level: type, "\(text, privacy: .public)")
        #else
        logger.log(level: type, "\(text, privacy: .private(mask: .hash))")
        #endif
    }
}

private extension Duration {
    var milliseconds: Double {
        let c = components
        return Double(c.seconds) * 1_000 + Double(c.attoseconds) * 1e-15
    }
}
