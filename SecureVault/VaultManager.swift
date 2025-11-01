//
//  VaultManager.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import Foundation
import CryptoKit

class VaultManager: ObservableObject {
    @Published var items: [VaultItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let databaseService = DatabaseService.shared

    // Initialize with master key
    func initialize(with key: SymmetricKey) {
        do {
            try databaseService.initialize(with: key)
            loadItems()
        } catch {
            self.error = "Failed to initialize database: \(error.localizedDescription)"
        }
    }

    // Add new item
    func addItem(_ item: VaultItem) {
        do {
            try databaseService.insert(item)
            items.append(item)
        } catch {
            self.error = "Failed to add item: \(error.localizedDescription)"
        }
    }

    // Update existing item
    func updateItem(_ item: VaultItem) {
        do {
            var updatedItem = item
            updatedItem.modifiedAt = Date()
            try databaseService.update(updatedItem)

            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updatedItem
            }
        } catch {
            self.error = "Failed to update item: \(error.localizedDescription)"
        }
    }

    // Delete item
    func deleteItem(_ item: VaultItem) {
        do {
            try databaseService.delete(item)
            items.removeAll { $0.id == item.id }
        } catch {
            self.error = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // Toggle favorite
    func toggleFavorite(_ item: VaultItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            do {
                try databaseService.update(items[index])
            } catch {
                self.error = "Failed to toggle favorite: \(error.localizedDescription)"
            }
        }
    }

    // Search items
    func searchItems(query: String) -> [VaultItem] {
        guard !query.isEmpty else { return items }

        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.content.localizedCaseInsensitiveContains(query)
        }
    }

    // Filter by type
    func filterItems(by type: ItemType?) -> [VaultItem] {
        guard let type = type else { return items }
        return items.filter { $0.type == type }
    }

    // Load items from database
    private func loadItems() {
        isLoading = true

        do {
            items = try databaseService.fetchAll()
        } catch {
            self.error = "Failed to load items: \(error.localizedDescription)"
            items = []
        }

        isLoading = false
    }

    // Export vault (encrypted database)
    func exportVault(to url: URL) throws {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SecureVault", isDirectory: true)
        let dbPath = appFolder.appendingPathComponent("securevault.db")

        guard fileManager.fileExists(atPath: dbPath.path) else {
            throw VaultError.noData
        }

        try fileManager.copyItem(at: dbPath, to: url)
    }

    // Import vault (encrypted database)
    func importVault(from url: URL) throws {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SecureVault", isDirectory: true)
        let dbPath = appFolder.appendingPathComponent("securevault.db")

        // Replace existing database
        if fileManager.fileExists(atPath: dbPath.path) {
            try fileManager.removeItem(at: dbPath)
        }

        try fileManager.copyItem(at: url, to: dbPath)
        loadItems()
    }
}

enum VaultError: Error {
    case noData
    case invalidData
}
