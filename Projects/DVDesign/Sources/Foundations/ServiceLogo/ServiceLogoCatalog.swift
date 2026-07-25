// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVServiceLogo {
    public let assetName: String
    public let brandColor: Color
}

/// `Secret.service` 자유 텍스트를 정규화해 번들된 브랜드 로고를 찾는다.
/// 매칭되는 항목이 없으면 `nil`을 반환하며, 호출부는 이니셜 플레이스홀더로 폴백해야 한다.
public enum ServiceLogoCatalog {

    public static func logo(forService service: String?) -> DVServiceLogo? {
        guard let service else { return nil }
        guard let canonical = aliases[normalize(service)] else { return nil }
        return entries[canonical]
    }

    private static func normalize(_ raw: String) -> String {
        raw.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    // 서비스별로 흔히 쓰이는 표기(별칭)를 대표 키로 매핑한다.
    private static let aliases: [String: String] = [
        "google": "google",
        "gmail": "google",
        "googleworkspace": "google",
        "github": "github",
        "naver": "naver",
        "kakao": "kakaotalk",
        "kakaotalk": "kakaotalk"
    ]

    private static let entries: [String: DVServiceLogo] = [
        "google": DVServiceLogo(assetName: "google", brandColor: Color(hex: 0x4285F4)),
        "github": DVServiceLogo(assetName: "github", brandColor: Color(hex: 0x181717)),
        "naver": DVServiceLogo(assetName: "naver", brandColor: Color(hex: 0x03C75A)),
        "kakaotalk": DVServiceLogo(assetName: "kakaotalk", brandColor: Color(hex: 0xFFCD00))
    ]
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
