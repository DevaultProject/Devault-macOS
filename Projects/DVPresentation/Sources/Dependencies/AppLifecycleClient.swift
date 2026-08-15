// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import Foundation

// MARK: - AppLifecycleEvent

/// 보안 상태를 되돌려야 하는 앱 수준 사건.
///
/// **트리거를 늘릴 때 case만 추가한다.** 구독자는 `RevealAuthPolicy.invalidates(on:)`으로
/// 반응 여부를 묻기 때문에, 화면 보호기·유휴 타임아웃·수동 잠금이 생겨도 Feature 로직은 그대로다.
/// (새 case를 넣으면 그 `switch`가 컴파일 에러로 잡아주므로 정책 반영을 빠뜨릴 수 없다.)
public enum AppLifecycleEvent: Equatable, Sendable {

    /// 앱이 활성 상태를 잃었다. macOS에서는 다른 앱으로 전환된 경우다.
    case didEnterBackground

    /// 잠금 화면으로 돌아갔다.
    ///
    /// 자동 잠금 기능이 아직 없어 현재 발신자가 없다. 기능이 생기면 그쪽에서 보내면 된다.
    case didLock
}

// MARK: - Client

/// 앱 수준 생명주기 사건을 Feature에 전달한다.
///
/// Feature가 `NSApplication` 알림을 직접 구독하지 않도록 한 겹 두는 이유는 두 가지다.
/// 감지 방식(알림·타이머·시스템 이벤트)이 바뀌어도 Feature가 영향받지 않고, 테스트에서
/// 원하는 시점에 이벤트를 밀어 넣을 수 있다.
@DependencyClient
public struct AppLifecycleClient: Sendable {

    /// 사건 스트림. 구독자마다 독립된 스트림을 받는다.
    public var events: @Sendable () -> AsyncStream<AppLifecycleEvent> = { .never }
}

extension AppLifecycleClient: TestDependencyKey {

    /// 즉시 종료되는 스트림. `.never`를 주면 구독 effect가 끝나지 않아 `TestStore`가
    /// 미완료 effect로 잡는다. 무효화를 검증하는 테스트만 직접 스트림을 주입한다.
    public static let testValue = AppLifecycleClient(events: { .finished })

    public static let previewValue = AppLifecycleClient(events: { .finished })
}

extension DependencyValues {

    public var appLifecycleClient: AppLifecycleClient {
        get { self[AppLifecycleClient.self] }
        set { self[AppLifecycleClient.self] = newValue }
    }
}
