// Copyright © 2026 Devault. All rights reserved

/// 한 번의 클립보드 복사에 어떤 보안 정책을 태울지 정하는 값.
///
/// 세 축 모두 값이 아니라 **참여 여부**만 둔다. 지연 시간·활성 여부 같은 값은 설정 화면이
/// 소유하므로 여기서 함께 들면 사용자가 바꾼 값이 무시된다.
public struct ClipboardCopyPolicy: Equatable, Sendable {

    /// 복사 전 사용자 인증을 요구할지. `true`여도 설정이 꺼져 있으면 인증하지 않는다.
    public var requiresAuthentication: Bool

    /// 복사 후 자동 정리를 이 복사에 적용할지. 지연 시간은 설정에서 읽는다.
    public var participatesInAutoClear: Bool

    /// 반복 복사 감지에 이 복사를 포함할지.
    public var participatesInRepeatDetection: Bool

    public init(
        requiresAuthentication: Bool,
        participatesInAutoClear: Bool,
        participatesInRepeatDetection: Bool
    ) {
        self.requiresAuthentication = requiresAuthentication
        self.participatesInAutoClear = participatesInAutoClear
        self.participatesInRepeatDetection = participatesInRepeatDetection
    }

    /// 시크릿 payload에서 온 값. 세 정책을 모두 설정에 맡긴다.
    public static let sensitive = ClipboardCopyPolicy(
        requiresAuthentication: true,
        participatesInAutoClear: true,
        participatesInRepeatDetection: true
    )

    /// metadata에서 온 평문. 붙여넣기 전에 사라지거나 오탐 경고를 만들면 안 되므로 어떤 정책도 태우지 않는다.
    public static let plain = ClipboardCopyPolicy(
        requiresAuthentication: false,
        participatesInAutoClear: false,
        participatesInRepeatDetection: false
    )
}
