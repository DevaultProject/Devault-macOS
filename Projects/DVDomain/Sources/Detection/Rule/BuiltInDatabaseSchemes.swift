// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 데이터베이스 · 메시지 큐 · 캐시 등 접속 URL scheme과 기본 포트 카탈로그.
enum BuiltInDatabaseSchemes {
    static let all: [DatabaseSchemeRule] = [
        .init(scheme: "postgres", defaultPort: 5432),
        .init(scheme: "postgresql", defaultPort: 5432),
        .init(scheme: "mysql", defaultPort: 3306),
        .init(scheme: "mongodb", defaultPort: 27017),
        .init(scheme: "mongodb+srv", defaultPort: nil),
        .init(scheme: "redis", defaultPort: 6379),
        .init(scheme: "rediss", defaultPort: 6379),
        .init(scheme: "amqp", defaultPort: 5672),
        .init(scheme: "amqps", defaultPort: 5672),
        .init(scheme: "clickhouse", defaultPort: 8123),
        .init(scheme: "influxdb", defaultPort: 8086),
        .init(scheme: "cloudinary", defaultPort: nil),
        .init(scheme: "libsql", defaultPort: nil),
    ]
}
