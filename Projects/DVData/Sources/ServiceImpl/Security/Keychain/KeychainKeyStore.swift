// Copyright © 2026 Devault. All rights reserved

import CryptoKit
import DVDomain
import Foundation
import Security

struct KeychainKeyStore: Sendable {
    private let service: String
    
    /// Keychain generic password item을 구분할 service namespace를 설정한다.
    init(service: String) {
        self.service = service
    }
    
    /// tag에 해당하는 symmetric key를 조회하고, 없으면 새 key를 생성해 Keychain에 저장한다.
    func getOrCreateSymmetricKey(tag: String) throws -> SymmetricKey {
        if let data = try loadKeyData(tag: tag) {
            return SymmetricKey(data: data)
        }
        
        let data = try generateKeyData()
        try saveKeyData(data, tag: tag)
        return SymmetricKey(data: data)
    }
    
    /// tag에 해당하는 symmetric key를 조회하고, 없으면 keyUnavailable 오류를 던진다.
    func getSymmetricKey(tag: String) throws -> SymmetricKey {
        guard let data = try loadKeyData(tag: tag) else {
            throw SecretCryptoError.keyUnavailable
        }
        
        return SymmetricKey(data: data)
    }
}

extension KeychainKeyStore {
    /// Keychain에서 tag에 해당하는 raw key Data를 조회한다.
    private func loadKeyData(tag: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tag,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // '키가 없음' -> 암호화 시점에서 key 새로 생성, 복호화 시점에서 keyUnavailable
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw SecretCryptoError.keyUnavailable
        }

        return data
    }

    /// raw key Data를 Keychain에 저장하고, 기존 item이 있으면 갱신한다.
    private func saveKeyData(_ data: Data, tag: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tag,
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        var addQuery = query
        attributes.forEach { addQuery[$0.key] = $0.value }

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecretCryptoError.keyUnavailable
            }
            return
        }

        guard status == errSecSuccess else {
            throw SecretCryptoError.keyUnavailable
        }
    }

    /// AES-256 symmetric key로 사용할 32바이트 랜덤 Data를 생성한다.
    private func generateKeyData() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let count = bytes.count
        let status = bytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }

        guard status == errSecSuccess else {
            throw SecretCryptoError.keyUnavailable
        }

        return Data(bytes)
    }
}
