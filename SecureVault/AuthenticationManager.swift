import Foundation
import LocalAuthentication
import CryptoKit

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationError: String?

    private let context = LAContext()
    private let keychainService = KeychainService.shared

    // Check if biometric authentication is available
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }

    // Get biometric type (Touch ID or Face ID)
    func biometricType() -> String {
        guard isBiometricAvailable() else { return "None" }

        switch context.biometryType {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        default:
            return "Biometric"
        }
    }

    // Authenticate using biometrics
    func authenticate() async {
        guard isBiometricAvailable() else {
            await MainActor.run {
                self.authenticationError = "Biometric authentication is not available on this device"
            }
            return
        }

        let reason = "Authenticate to access your secure vault"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            await MainActor.run {
                if success {
                    self.isAuthenticated = true
                    self.authenticationError = nil
                } else {
                    self.authenticationError = "Authentication failed"
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.authenticationError = error.localizedDescription
            }
        }
    }

    // Lock the vault
    func lock() {
        isAuthenticated = false
    }

    // Get or create master key
    func getMasterKey() throws -> SymmetricKey {
        // Try to retrieve existing key from Keychain
        if let keyData = keychainService.retrieveKey(identifier: "masterKey") {
            return SymmetricKey(data: keyData)
        }

        // Generate new master key
        let masterKey = EncryptionService.shared.generateMasterKey()
        let keyData = masterKey.withUnsafeBytes { Data($0) }

        // Store in Keychain
        try keychainService.storeKey(keyData, identifier: "masterKey")

        return masterKey
    }
}
