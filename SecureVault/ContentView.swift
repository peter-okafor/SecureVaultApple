//
//  ContentView.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import SwiftUI

struct ContentView: View {
     @EnvironmentObject var authManager: AuthenticationManager
     @EnvironmentObject var vaultManager: VaultManager

    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                VaultListView()
            } else {
                LockScreenView()
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth {
                // Initialize vault with master key
                do {
                    let masterKey = try authManager.getMasterKey()
                    vaultManager.initialize(with: masterKey)
                } catch {
                    authManager.authenticationError = "Failed to initialize vault"
                }
            }
        }
    }
}

struct LockScreenView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("SecureVault")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your passwords, keys, and notes\nsecurely encrypted")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if let error = authManager.authenticationError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            Button(action: {
                Task {
                    await authManager.authenticate()
                }
            }) {
                HStack {
                    Image(systemName: authManager.isBiometricAvailable() ? "touchid" : "lock.fill")
                    Text("Unlock with \(authManager.biometricType())")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 280)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

//#Preview {
//    ContentView()
//}
