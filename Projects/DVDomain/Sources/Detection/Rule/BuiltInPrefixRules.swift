// Copyright © 2026 Devault. All rights reserved

import Foundation

/// 앱 번들에 정적으로 임베드된 prefix rule 카탈로그. 카테고리별로 서브네임스페이스에 나누어 관리한다.
enum BuiltInPrefixRules {
    /// AI · LLM 서비스 API key prefix.
    static let ai: [PrefixRule] = [
        .init(prefix: "sk-ant-", service: "Anthropic", displayLabel: "Anthropic API Key", confidence: .high),
        .init(prefix: "sk-or-", service: "OpenRouter", displayLabel: "OpenRouter API Key", confidence: .high),
        .init(prefix: "sk-", minLength: 48, requiresContext: "stability",
              service: "Stability AI", displayLabel: "Stability AI API Key", confidence: .high),
        .init(prefix: "sk-", minLength: 48,
              service: "OpenAI", displayLabel: "OpenAI API Key", confidence: .medium),
        .init(prefix: "hf_", service: "Hugging Face", displayLabel: "Hugging Face Token", confidence: .high),
        .init(prefix: "r8_", service: "Replicate", displayLabel: "Replicate API Key", confidence: .high),
        .init(prefix: "gsk_", service: "Groq", displayLabel: "Groq API Key", confidence: .high),
        .init(prefix: "pplx-", service: "Perplexity", displayLabel: "Perplexity API Key", confidence: .high),
        .init(prefix: "pk.eyJ", service: "Mapbox", displayLabel: "Mapbox Public Token", confidence: .high),
        .init(prefix: "sk.eyJ", service: "Mapbox", displayLabel: "Mapbox Secret Token", confidence: .high),
    ]

    /// 결제 관련 서비스 prefix.
    static let payments: [PrefixRule] = [
        .init(prefix: "sk_live_", service: "Stripe", displayLabel: "Stripe Live Key", confidence: .high),
        .init(prefix: "sk_test_", service: "Stripe", displayLabel: "Stripe Test Key", confidence: .high),
        .init(prefix: "whsec_", service: "Stripe", displayLabel: "Stripe Webhook Secret", confidence: .high),
        .init(prefix: "rk_live_", service: "Stripe", displayLabel: "Stripe Restricted Live Key", confidence: .high),
        .init(prefix: "rk_test_", service: "Stripe", displayLabel: "Stripe Restricted Test Key", confidence: .high),
        .init(prefix: "sq0atp-", service: "Square", displayLabel: "Square Access Token", confidence: .high),
        .init(prefix: "sq0csp-", service: "Square", displayLabel: "Square Client Secret", confidence: .high),
        .init(prefix: "rzp_live_", service: "Razorpay", displayLabel: "Razorpay Live Key", confidence: .high),
        .init(prefix: "rzp_test_", service: "Razorpay", displayLabel: "Razorpay Test Key", confidence: .high),
        .init(prefix: "access-production-", service: "Plaid", displayLabel: "Plaid Production Token", confidence: .high),
        .init(prefix: "access-sandbox-", service: "Plaid", displayLabel: "Plaid Sandbox Token", confidence: .high),
        .init(prefix: "access_token$production$", service: "Braintree", displayLabel: "Braintree Production Token", confidence: .high),
        .init(prefix: "access_token$sandbox$", service: "Braintree", displayLabel: "Braintree Sandbox Token", confidence: .high),
    ]

    /// 소스 컨트롤 · 배포 · 시크릿 관리 서비스 prefix.
    static let devops: [PrefixRule] = [
        .init(prefix: "ghp_", service: "GitHub", displayLabel: "GitHub Personal Access Token", confidence: .high),
        .init(prefix: "gho_", service: "GitHub", displayLabel: "GitHub OAuth Token", confidence: .high),
        .init(prefix: "ghs_", service: "GitHub", displayLabel: "GitHub App Token", confidence: .high),
        .init(prefix: "ghr_", service: "GitHub", displayLabel: "GitHub Refresh Token", confidence: .high),
        .init(prefix: "glpat-", service: "GitLab", displayLabel: "GitLab Personal Access Token", confidence: .high),
        .init(prefix: "gldt-", service: "GitLab", displayLabel: "GitLab Deploy Token", confidence: .high),
        .init(prefix: "ATBB", service: "Bitbucket", displayLabel: "Bitbucket App Password", confidence: .high),
        .init(prefix: "npm_", service: "npm", displayLabel: "npm Access Token", confidence: .high),
        .init(prefix: "vc_", service: "Vercel", displayLabel: "Vercel Token", confidence: .high),
        .init(prefix: "rnd_", service: "Render", displayLabel: "Render API Key", confidence: .high),
        .init(prefix: "dp.st.", service: "Doppler", displayLabel: "Doppler Service Token", confidence: .high),
        .init(prefix: "s.", minLength: 24,
              service: "HashiCorp Vault", displayLabel: "HashiCorp Vault Token", confidence: .medium),
    ]

    /// 클라우드 · 인프라 서비스 prefix.
    static let cloud: [PrefixRule] = [
        .init(prefix: "AKIA", minLength: 20,
              service: "AWS", displayLabel: "AWS Access Key ID", confidence: .high),
        .init(prefix: "AIza", minLength: 39,
              service: "Google", displayLabel: "Google API Key", confidence: .high),
        .init(prefix: "dop_v1_", service: "DigitalOcean", displayLabel: "DigitalOcean Personal Token", confidence: .high),
    ]

    /// 커뮤니케이션 · 메시징 서비스 prefix (Twilio · Mailchimp 등 regex 형태는 `BuiltInRegexRules` 참조).
    static let communication: [PrefixRule] = [
        .init(prefix: "xoxb-", service: "Slack", displayLabel: "Slack Bot Token", confidence: .high),
        .init(prefix: "xoxp-", service: "Slack", displayLabel: "Slack User Token", confidence: .high),
        .init(prefix: "xoxa-", service: "Slack", displayLabel: "Slack App Token", confidence: .high),
        .init(prefix: "xoxs-", service: "Slack", displayLabel: "Slack Workspace Token", confidence: .high),
        .init(prefix: "SG.", service: "SendGrid", displayLabel: "SendGrid API Key", confidence: .high),
        .init(prefix: "key-", minLength: 36,
              service: "Mailgun", displayLabel: "Mailgun API Key", confidence: .medium),
        .init(prefix: "oauth:", service: "Twitch", displayLabel: "Twitch IRC OAuth Token", confidence: .high),
        .init(prefix: "AAAA", minLength: 80,
              service: "Twitter", displayLabel: "Twitter Bearer Token", confidence: .medium),
        .init(prefix: "EAA", service: "Meta", displayLabel: "Meta Access Token", confidence: .medium),
    ]

    /// 모니터링 · 분석 서비스 prefix (Sentry DSN 등은 `BuiltInRegexRules` 참조).
    static let monitoring: [PrefixRule] = [
        .init(prefix: "NRAK-", service: "New Relic", displayLabel: "New Relic User Key", confidence: .high),
        .init(prefix: "glc_", service: "Grafana", displayLabel: "Grafana Service Account Token", confidence: .high),
    ]

    /// SaaS · 개발 도구 prefix.
    static let saas: [PrefixRule] = [
        .init(prefix: "shpss_", service: "Shopify", displayLabel: "Shopify Private App Token", confidence: .high),
        .init(prefix: "shpat_", service: "Shopify", displayLabel: "Shopify Access Token", confidence: .high),
        .init(prefix: "shpca_", service: "Shopify", displayLabel: "Shopify Custom App Token", confidence: .high),
        .init(prefix: "pat-na1-", service: "HubSpot", displayLabel: "HubSpot Private App Token", confidence: .high),
        .init(prefix: "pat-eu1-", service: "HubSpot", displayLabel: "HubSpot Private App Token", confidence: .high),
        .init(prefix: "secret_", service: "Notion", displayLabel: "Notion API Key", confidence: .high),
        .init(prefix: "lin_api_", service: "Linear", displayLabel: "Linear API Key", confidence: .high),
        .init(prefix: "sbp_", service: "Supabase", displayLabel: "Supabase Token", confidence: .high),
        .init(prefix: "pscale_tkn_", service: "PlanetScale", displayLabel: "PlanetScale Token", confidence: .high),
        .init(prefix: "pat", requiresContext: ".",
              service: "Airtable", displayLabel: "Airtable Personal Token", confidence: .medium),
    ]

    /// OAuth 전용 토큰 prefix (§2-2).
    static let oauth: [PrefixRule] = [
        .init(prefix: "ya29.", service: "Google", displayLabel: "Google OAuth Access Token", confidence: .high),
    ]

    /// prefix 길이 내림차순으로 정렬한 통합 목록. 짧은 prefix(예: `sk-`)가 긴 prefix(예: `sk-ant-`)보다
    /// 먼저 매칭돼 오탐하는 것을 막기 위한 순서 보장.
    static var all: [PrefixRule] {
        (ai + payments + devops + cloud + communication + monitoring + saas + oauth)
            .sorted { $0.prefix.count > $1.prefix.count }
    }
}
