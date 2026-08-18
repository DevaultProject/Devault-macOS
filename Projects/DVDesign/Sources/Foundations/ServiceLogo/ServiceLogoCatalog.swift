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
            aliases: ["google", "gmail", "googleworkspace", "구글"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "github", brandColor: Color(hex: 0x181717), rendersAsTemplate: true),
            aliases: ["github", "깃허브"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "naver", brandColor: Color(hex: 0x03C75A), rendersAsTemplate: true),
            aliases: ["naver", "네이버"]
        ),
        Entry(
            // 카카오 심볼(말풍선)은 브랜드 규정상 글리프가 항상 브라운 고정이라 흰색 관례를 따르지 않는다.
            logo: DVServiceLogo(
                assetName: "kakao",
                brandColor: Color(hex: 0xFFCD00),
                rendersAsTemplate: true,
                glyphColor: Color(hex: 0x391B1B)
            ),
            aliases: ["kakao", "kakaotalk", "카카오", "카카오톡"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "paypal", brandColor: Color(hex: 0x002991), rendersAsTemplate: true),
            aliases: ["paypal", "페이팔"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "azure", brandColor: Color(hex: 0x0089D6), rendersAsTemplate: true),
            aliases: ["azure", "애저"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "cloudinary", brandColor: Color(hex: 0x3448C5), rendersAsTemplate: true),
            aliases: ["cloudinary", "클라우디너리"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "firebase", brandColor: Color(hex: 0xDD2C00), rendersAsTemplate: true),
            aliases: ["firebase", "파이어베이스"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "notion", brandColor: Color(hex: 0x000000), rendersAsTemplate: true),
            aliases: ["notion", "노션"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "discord", brandColor: Color(hex: 0x5865F2), rendersAsTemplate: true),
            aliases: ["discord", "디스코드"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "slack", brandColor: Color(hex: 0x4A154B), rendersAsTemplate: true),
            aliases: ["slack", "슬랙"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "anthropic", brandColor: Color(hex: 0x191919), rendersAsTemplate: true),
            aliases: ["anthropic", "앤트로픽"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "huggingface", brandColor: Color(hex: 0xFFD21E), rendersAsTemplate: true),
            aliases: ["huggingface", "허깅페이스"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "gitlab", brandColor: Color(hex: 0xFC6D26), rendersAsTemplate: true),
            aliases: ["gitlab", "깃랩"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "npm", brandColor: Color(hex: 0xCB3837), rendersAsTemplate: true),
            aliases: ["npm"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "vercel", brandColor: Color(hex: 0x000000), rendersAsTemplate: true),
            aliases: ["vercel", "버셀"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "stripe", brandColor: Color(hex: 0x635BFF), rendersAsTemplate: true),
            aliases: ["stripe", "스트라이프"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "sentry", brandColor: Color(hex: 0x362D59), rendersAsTemplate: true),
            aliases: ["sentry", "센트리"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "telegram", brandColor: Color(hex: 0x26A5E4), rendersAsTemplate: true),
            aliases: ["telegram", "텔레그램"]
        ),
        Entry(
            logo: DVServiceLogo(assetName: "twilio", brandColor: Color(hex: 0xF22F46), rendersAsTemplate: true),
            aliases: ["twilio", "트윌리오"]
        ),
    ]

    private static let logosByAlias: [String: DVServiceLogo] = entries.reduce(into: [:]) { result, entry in
        for alias in entry.aliases {
            result[alias] = entry.logo
        }
    }
}
