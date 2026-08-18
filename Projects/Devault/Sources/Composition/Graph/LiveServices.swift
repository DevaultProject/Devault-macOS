// Copyright © 2026 Devault. All rights reserved

import DVData
import DVDomain
import DVPresentation

/// Composition Root 전체에서 공유하는 Service 인스턴스. 알림 문구는 DVData가 접근 못 하는 로컬라이제이션 카탈로그 때문에 `SecurityNotification.moduleContent(for:)`(DVPresentation)에서 만들어 주입한다.
enum LiveServices {
    static let securityNotification: any SecurityNotificationService = SecurityNotificationServiceImpl(
        makeContent: SecurityNotification.moduleContent(for:)
    )
}
