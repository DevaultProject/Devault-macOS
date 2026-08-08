// Copyright © 2026 Devault. All rights reserved

import ComposableArchitecture
import DVDomain
import Foundation

// MARK: - SecretDetailError

/// Secret 조회/복호화 실패 시 Presentation 계층 오류.
enum SecretDetailError: Equatable {
    /// 생체인증·패스코드 인증 요구.
    case authRequired
    /// 복호화 실패 (키 없음·복호화 오류·디코딩 실패).
    case decryptionFailed
    /// 그 외 예기치 않은 오류.
    case unexpected

    static func map(_ error: SecretUseCaseError) -> SecretDetailError {
        switch error {
        case .authenticationFailure:
            return .authRequired
        case .cryptoFailure(let crypto):
            switch crypto {
            case .keyUnavailable, .keychainFailure,
                 .decryptionFailed, .decodingFailed:
                return .decryptionFailed
            case .encryptionFailed, .encodingFailed:
                return .unexpected
            }
        case .secretNotFound, .repositoryFailure,
             .invalidName, .invalidSecretType, .unexpected:
            return .unexpected
        }
    }
}

// MARK: - AlertState Presets

extension AlertState where Action == SecretDetailFeature.Action.Alert {

    static func payloadRevealFailed(_ error: SecretDetailError) -> Self {
        switch error {
        case .authRequired:
            return Self {
                TextState("Authentication required", bundle: .module)
            } actions: {
                ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
            } message: {
                TextState(
                    "Please authenticate to view the secret.",
                    bundle: .module
                )
            }

        case .decryptionFailed:
            return Self {
                TextState("Failed to reveal secret", bundle: .module)
            } actions: {
                ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
            } message: {
                TextState(
                    "The secret could not be decrypted. Check that your device passcode is enabled.",
                    bundle: .module
                )
            }

        case .unexpected:
            return Self {
                TextState("Failed to reveal secret", bundle: .module)
            } actions: {
                ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
            } message: {
                TextState(
                    "An unexpected error occurred. Please try again.",
                    bundle: .module
                )
            }
        }
    }

    static var confirmDiscard: Self {
        Self {
            TextState("Discard changes?", bundle: .module)
        } actions: {
            ButtonState(role: .destructive, action: .confirmDiscard) {
                TextState("Discard", bundle: .module)
            }
            ButtonState(role: .cancel) {
                TextState("Keep editing", bundle: .module)
            }
        } message: {
            TextState(
                "Your unsaved changes will be lost.",
                bundle: .module
            )
        }
    }
}
