// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

func expectCodableRoundtrip<T: Codable & Equatable>(
    _ value: T,
    sourceLocation: SourceLocation = #_sourceLocation
) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value, sourceLocation: sourceLocation)
}
