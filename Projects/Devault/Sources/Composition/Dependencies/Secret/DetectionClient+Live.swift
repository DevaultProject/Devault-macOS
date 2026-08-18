// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import DVPresentation

extension DetectionClient: @retroactive DependencyKey {
    public static let liveValue: DetectionClient = {
        let useCase: any DetectSecretUseCase = DetectSecretUseCaseImpl()
        return DetectionClient(
            detect: { value in useCase.execute(value: value) }
        )
    }()
}
