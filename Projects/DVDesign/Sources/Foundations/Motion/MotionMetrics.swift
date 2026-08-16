// Copyright © 2026 Devault. All rights reserved

import SwiftUI

// MARK: - MotionMetrics

/// 화면 전환·재배치에 쓰는 움직임 토큰.
///
/// **용도로 나누고 시간은 공유한다.** 겹쳐 넘기는 것과 자리를 옮기는 것은 곡선이 달라야
/// 자연스럽지만, 길이가 다르면 함께 일어날 때 따로 논다 — 사이드바를 한 번 누르면 목록과
/// 상세가 같이 움직인다.
public enum MotionMetrics {

    // MARK: - Duration

    /// 더 길면 굼떠 보이고, 더 짧으면 전환이 아니라 깜빡임으로 읽힌다.
    public static let standardDuration: TimeInterval = 0.25

    /// 눈길을 끌면 안 되는 변화.
    public static let subtleDuration: TimeInterval = 0.18

    /// 커서보다 느리면 굼떠 보이므로 눈에 띄게 짧다.
    public static let hoverDuration: TimeInterval = 0.12

    // MARK: - Animation

    /// **내용이 갈릴 때.** 화면 전환, 컬럼 내용 교체.
    public static let transition: Animation = .easeInOut(duration: standardDuration)

    /// **위치나 크기가 움직일 때.** 행 재배치, 섹션 접고 펴기.
    public static let layout: Animation = .smooth(duration: standardDuration)

    /// **값만 살짝 바뀔 때.** 갱신 중 흐리기 등.
    public static let subtle: Animation = .easeInOut(duration: subtleDuration)

    /// **hover·선택 되먹임.**
    public static let hover: Animation = .easeOut(duration: hoverDuration)
}
