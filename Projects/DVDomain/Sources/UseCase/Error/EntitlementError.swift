// Copyright © 2026 Devault. All rights reserved

/// 무료 티어 게이트에 걸려 동작이 거부됐다.
///
/// **게이트로 막힌 모든 경로가 이 타입 하나를 던진다.** 도메인마다 다른 에러에 케이스를 흩어 두면 호출부가 "지금 페이월을 띄워야 하나"를 판단하려고 네 가지를 각각 잡아야 한다. 여기 있는 것을 잡으면 곧 업그레이드 시트를 띄우면 된다.
///
/// **판정 실패는 이 타입이 아니다.** 개수를 세다 저장소가 실패하면 각 도메인의 오류(`SecretUseCaseError` 등)로 전달된다 — 그건 결제로 해결되지 않으므로 페이월을 띄우면 안 된다.
public enum EntitlementError: Error, Equatable, Sendable {

    /// 구독해야 쓸 수 있는 기능이다. iCloud 동기화, 만료 알림 다중 시점.
    case requiresPro

    /// 무료 한도에 도달해 더 만들 수 없다. Secret 15개, Project 1개.
    case limitReached

    /// 보유 수가 한도를 넘겨 수정이 잠겼다. 줄이거나 구독해야 풀린다. 조회·복사·즐겨찾기·삭제는 계속 허용된다.
    case editLocked
}
