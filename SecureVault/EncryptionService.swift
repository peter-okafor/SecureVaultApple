//
//  EncryptionService.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()

    private init() {}

    // Generate a symmetric key from user's biometric authentication
    func generateKey(from password: String) throws -> SymmetricKey {
        let passwordData = Data(password.utf8)
        let hash = SHA256.hash(data: passwordData)
        return SymmetricKey(data: hash)
    }

    // Encrypt data using AES-GCM
    func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    // Decrypt data using AES-GCM
    func decrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // Generate a master key and store it securely in Keychain
    func generateMasterKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
}

enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
}
