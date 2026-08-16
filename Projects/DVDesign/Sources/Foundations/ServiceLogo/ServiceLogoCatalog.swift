// Copyright © 2026 Devault. All rights reserved

import SwiftUI

public struct DVServiceLogo {
    public let assetName: String
    public let brandColor: Color
    /// `false`면 SVG가 배경과 글리프를 한 path로 합쳐 그린다.
    /// 이런 에셋은 `.template` 틴트를 걸면 배경까지 단색으로 뭉개지므로 원본 색상 그대로 그려야 한다.
    public let rendersAsTemplate: Bool
    /// `rendersAsTemplate`일 때 글리프에 입힐 색. 기본은 흰색(원형 배경 위 아이콘 관례).
    /// 카카오처럼 브랜드 규정상 글리프 색이 고정된 경우에만 다르게 지정한다.
    public let glyphColor: Color

    public init(
        assetName: String,
        brandColor: Color,
        rendersAsTemplate: Bool,
        glyphColor: Color = Color.dv(.white)
    ) {
        self.assetName = assetName
        self.brandColor = brandColor
        self.rendersAsTemplate = rendersAsTemplate
        self.glyphColor = glyphColor
    }
}

/// `Secret.service` 자유 텍스트를 정규화해 번들된 브랜드 로고를 찾는다.
/// 매칭되는 항목이 없으면 `nil`을 반환하며, 호출부는 이니셜 플레이스홀더로 폴백해야 한다.
public enum ServiceLogoCatalog {

    public static func logo(forService service: String?) -> DVServiceLogo? {
        guard let service else { return nil }
        return logosByAlias[normalize(service)]
    }

    /// 영문/숫자만 남기고 비교한다. "Google Cloud"처럼 알려지지 않은 표기는
    /// `aliases`에 미리 추가해두지 않는 한 조용히 매칭 실패해 이니셜 폴백으로 빠진다.
    private static func normalize(_ raw: String) -> String {
        raw.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private struct Entry {
        let logo: DVServiceLogo
        let aliases: [String]
    }

    private static let entries: [Entry] = [
        Entry(
            logo: DVServiceLogo(assetName: "google", brandColor: Color(hex: 0x4285F4), rendersAsTemplate: true),
            aliases: ["google", "gmail", "googleworkspace"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "github", brandColor: Color(hex: 0x181717), rendersAsTemplate: true),
            aliases: ["github"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "naver", brandColor: Color(hex: 0x03C75A), rendersAsTemplate: true),
            aliases: ["naver"]
        ),
        Entry(
            // 카카오 심볼(말풍선)은 브랜드 규정상 글리프가 항상 브라운 고정이라 흰색 관례를 따르지 않는다.
            logo: DVServiceLogo(
                assetName: "kakao",
                brandColor: Color(hex: 0xFFCD00),
                rendersAsTemplate: true,
                glyphColor: Color(hex: 0x391B1B)
            ),
            aliases: ["kakao", "kakaotalk"]
        ),
    ]

    private static let logosByAlias: [String: DVServiceLogo] = entries.reduce(into: [:]) { result, entry in
        for alias in entry.aliases {
            result[alias] = entry.logo
        }
    }
}
