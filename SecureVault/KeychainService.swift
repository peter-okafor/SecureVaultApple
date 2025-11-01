//
//  KeychainService.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import Foundation
import Security

/// KeychainService - Securely stores encryption keys in the system Keychain
/// This service ONLY stores encryption keys, not the actual vault data.
/// All vault items are stored encrypted in the SQLite database.
class KeychainService {
    static let shared = KeychainService()

    private init() {}

    // Store encryption key in Keychain (not vault data)
    func storeKey(_ keyData: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }

    // Retrieve key from Keychain
    func retrieveKey(identifier: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }

        return keyData
    }

    // Delete key from Keychain
    func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToStore
    case unableToRetrieve
    case unableToDelete
}
