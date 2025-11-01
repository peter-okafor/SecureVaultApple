//
//  SecureVaultApp.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import SwiftUI

@main
struct SecureVaultApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var vaultManager = VaultManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(vaultManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
