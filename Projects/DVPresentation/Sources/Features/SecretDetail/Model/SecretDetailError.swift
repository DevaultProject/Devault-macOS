// Copyright © 2026 Devault. All rights reserved

import Foundation

import ComposableArchitecture
import DVDomain

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

    /// 조회 화면에 남는 안내 문구. alert는 닫히면 사라지므로 원인은 화면에서도 읽혀야 한다.
    var revealFailureMessage: LocalizedStringResource {
        switch self {
        case .authRequired:
            return .module("Authentication is required to reveal this secret.")
        case .decryptionFailed, .unexpected:
            return .module("This secret could not be decrypted.")
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

    /// 즐겨찾기 갱신 실패. payload 복호화가 없는 경로이므로 인증 실패는 나오지 않는다.
    static var likeFailed: Self {
        Self {
            TextState("Failed to update favorite", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
        } message: {
            TextState(
                "An unexpected error occurred. Please try again.",
                bundle: .module
            )
        }
    }

    static var confirmDelete: Self {
        Self {
            TextState("Move to trash?", bundle: .module)
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete) {
                TextState("Delete", bundle: .module)
            }
            ButtonState(role: .cancel) {
                TextState("Cancel", bundle: .module)
            }
        } message: {
            TextState(
                "You can restore it later from Trash.",
                bundle: .module
            )
        }
    }

    static var deleteFailed: Self {
        Self {
            TextState("Failed to delete secret", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
        } message: {
            TextState(
                "An unexpected error occurred. Please try again.",
                bundle: .module
            )
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
