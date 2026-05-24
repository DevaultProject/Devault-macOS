// Copyright © 2026 Devault. All rights reserved

import SwiftUI
import DVDesign

struct TextContainerPreviewView: View {
    @Environment(\.openURL) private var openURL
    @State private var copyableFeedback: String?
    @State private var multiCopyFeedback: String?
    @State private var manualRevealed = false
    @State private var securedRevealed = false
    private let secret = "DeVault"
    private let externalURL = URL(string: "https://www.naver.com")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "상태") {
                    labeled("Filled (액세서리 없음, 좌우 8pt 대칭 padding)") {
                        DVTextContainer("DeVault", size: .md)
                    }
                    labeled("Empty (액세서리 없음)") {
                        DVTextContainer("", size: .md)
                    }
                    labeled("긴 텍스트 — 가로 스크롤 (트랙패드 두 손가락 / 마우스 휠)") {
                        DVTextContainer(
                            "이 텍스트는 컨테이너 width보다 충분히 길어서 잘리지 않고 가로로 스크롤됩니다. 사용자는 트랙패드나 마우스 휠로 가려진 부분까지 모두 확인할 수 있습니다.",
                            size: .md
                        )
                    }
                }

                section(title: "Interactive 액세서리 — Button 액션이 텍스트에 영향") {
                    labeled("copyable: 편의 init (클립보드 + 피드백 라벨)") {
                        HStack(spacing: 12) {
                            DVTextContainer(copyable: "vault-token-7af3", size: .md) {
                                copyToClipboard("vault-token-7af3")
                                copyableFeedback = "복사됨"
                            }
                            if let feedback = copyableFeedback {
                                Text(feedback)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .transition(.opacity)
                            }
                        }
                    }

                    labeled("secured: 편의 init (마스킹 + 눈 토글)") {
                        DVTextContainer(
                            secured: secret,
                            isRevealed: $securedRevealed,
                            size: .md
                        )
                    }

                    labeled("onTap:icon: — 커스텀 단일 액세서리 (탭하면 브라우저로 열기)") {
                        DVTextContainer(
                            externalURL.absoluteString,
                            size: .md,
                            onTap: { openURL(externalURL) }
                        ) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.dv(.gray900))
                        }
                    }

                    labeled("기본 init — 멀티 액세서리 (copy + 눈 토글 동시)") {
                        HStack(spacing: 12) {
                            DVTextContainer(
                                manualRevealed ? secret : String(repeating: "•", count: secret.count),
                                size: .md
                            ) {
                                HStack(spacing: 10) {
                                    Button {
                                        copyToClipboard(secret)
                                        multiCopyFeedback = "복사됨"
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    Button {
                                        manualRevealed.toggle()
                                    } label: {
                                        Image(systemName: manualRevealed ? "eye.slash" : "eye")
                                    }
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(Color.dv(.gray900))
                                .buttonStyle(.plain)
                            }
                            if let feedback = multiCopyFeedback {
                                Text(feedback)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .transition(.opacity)
                            }
                        }
                    }
                }

                section(title: "사이즈") {
                    labeled("XS (180pt)") { DVTextContainer("XS DeVault", size: .xs) }
                    labeled("SM (330pt)") { DVTextContainer("SM DeVault", size: .sm) }
                    labeled("MD (380pt)") { DVTextContainer("MD DeVault", size: .md) }
                    labeled("LG (700pt)") { DVTextContainer("LG DeVault", size: .lg) }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("TextContainer")
    }

    private func copyToClipboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title2).fontWeight(.bold)
            content()
        }
    }

    @ViewBuilder
    private func labeled<Content: View>(
        _ caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}
