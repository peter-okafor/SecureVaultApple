//
//  DatabaseService.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import Foundation
import SQLite
import CryptoKit


class DatabaseService {
    static let shared = DatabaseService()

    private var db: Connection?
    private let encryptionService = EncryptionService.shared
    private var encryptionKey: SymmetricKey?

    // Table definition
    private let vaultItems = Table("vault_items")

    // Columns
    private let id = Expression<String>("id")
    private let type = Expression<String>("type")
    private let title = Expression<Data>("title") // Encrypted
    private let content = Expression<Data>("content") // Encrypted
    private let metadata = Expression<Data>("metadata") // Encrypted
    private let createdAt = Expression<Date>("created_at")
    private let modifiedAt = Expression<Date>("modified_at")
    private let isFavorite = Expression<Bool>("is_favorite")

    private init() {}

    // Database file location
    private var databaseURL: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SecureVault", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        return appFolder.appendingPathComponent("securevault.db")
    }

    // Initialize database with encryption key
    func initialize(with key: SymmetricKey) throws {
        self.encryptionKey = key

        // Connect to database
        db = try Connection(databaseURL.path)

        // Create table if it doesn't exist
        try createTableIfNeeded()
    }

    // Create table schema
    private func createTableIfNeeded() throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        try db.run(vaultItems.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(type)
            table.column(title)
            table.column(content)
            table.column(metadata)
            table.column(createdAt)
            table.column(modifiedAt)
            table.column(isFavorite)
        })
    }

    // MARK: - CRUD Operations

    // Insert item
    func insert(_ item: VaultItem) throws {
        guard let db = db, let key = encryptionKey else {
            throw DatabaseError.notInitialized
        }

        // Encrypt sensitive data
        let encryptedTitle = try encryptionService.encrypt(data: Data(item.title.utf8), using: key)
        let encryptedContent = try encryptionService.encrypt(data: Data(item.content.utf8), using: key)

        // Encode and encrypt metadata
        let metadataJson = try JSONEncoder().encode(item.metadata)
        let encryptedMetadata = try encryptionService.encrypt(data: metadataJson, using: key)

        // Insert into database
        let insert = vaultItems.insert(
            id <- item.id.uuidString,
            type <- item.type.rawValue,
            title <- encryptedTitle,
            content <- encryptedContent,
            metadata <- encryptedMetadata,
            createdAt <- item.createdAt,
            modifiedAt <- item.modifiedAt,
            isFavorite <- item.isFavorite
        )

        try db.run(insert)
    }

    // Update item
    func update(_ item: VaultItem) throws {
        guard let db = db, let key = encryptionKey else {
            throw DatabaseError.notInitialized
        }

        // Encrypt sensitive data
        let encryptedTitle = try encryptionService.encrypt(data: Data(item.title.utf8), using: key)
        let encryptedContent = try encryptionService.encrypt(data: Data(item.content.utf8), using: key)

        // Encode and encrypt metadata
        let metadataJson = try JSONEncoder().encode(item.metadata)
        let encryptedMetadata = try encryptionService.encrypt(data: metadataJson, using: key)

        // Update in database
        let itemToUpdate = vaultItems.filter(id == item.id.uuidString)
        try db.run(itemToUpdate.update(
            type <- item.type.rawValue,
            title <- encryptedTitle,
            content <- encryptedContent,
            metadata <- encryptedMetadata,
            modifiedAt <- item.modifiedAt,
            isFavorite <- item.isFavorite
        ))
    }

    // Delete item
    func delete(_ item: VaultItem) throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let itemToDelete = vaultItems.filter(id == item.id.uuidString)
        try db.run(itemToDelete.delete())
    }

    // Fetch all items
    func fetchAll() throws -> [VaultItem] {
        guard let db = db, let key = encryptionKey else {
            throw DatabaseError.notInitialized
        }

        var items: [VaultItem] = []

        for row in try db.prepare(vaultItems) {
            // Decrypt data
            let decryptedTitle = try encryptionService.decrypt(data: row[title], using: key)
            let decryptedContent = try encryptionService.decrypt(data: row[content], using: key)
            let decryptedMetadata = try encryptionService.decrypt(data: row[metadata], using: key)

            // Parse decrypted data
            let titleString = String(data: decryptedTitle, encoding: .utf8) ?? ""
            let contentString = String(data: decryptedContent, encoding: .utf8) ?? ""
            let metadataDict = try JSONDecoder().decode([String: String].self, from: decryptedMetadata)

            // Create VaultItem
            let item = VaultItem(
                id: UUID(uuidString: row[id]) ?? UUID(),
                type: ItemType(rawValue: row[type]) ?? .password,
                title: titleString,
                content: contentString,
                metadata: metadataDict,
                createdAt: row[createdAt],
                modifiedAt: row[modifiedAt],
                isFavorite: row[isFavorite]
            )

            items.append(item)
        }

        return items
    }

    // Fetch item by ID
    func fetch(byId itemId: UUID) throws -> VaultItem? {
        guard let db = db, let key = encryptionKey else {
            throw DatabaseError.notInitialized
        }

        let query = vaultItems.filter(id == itemId.uuidString)

        guard let row = try db.pluck(query) else {
            return nil
        }

        // Decrypt data
        let decryptedTitle = try encryptionService.decrypt(data: row[title], using: key)
        let decryptedContent = try encryptionService.decrypt(data: row[content], using: key)
        let decryptedMetadata = try encryptionService.decrypt(data: row[metadata], using: key)

        // Parse decrypted data
        let titleString = String(data: decryptedTitle, encoding: .utf8) ?? ""
        let contentString = String(data: decryptedContent, encoding: .utf8) ?? ""
        let metadataDict = try JSONDecoder().decode([String: String].self, from: decryptedMetadata)

        return VaultItem(
            id: UUID(uuidString: row[id]) ?? UUID(),
            type: ItemType(rawValue: row[type]) ?? .password,
            title: titleString,
            content: contentString,
            metadata: metadataDict,
            createdAt: row[createdAt],
            modifiedAt: row[modifiedAt],
            isFavorite: row[isFavorite]
        )
    }

    // Delete all items (useful for resetting vault)
    func deleteAll() throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        try db.run(vaultItems.delete())
    }

    // Check if database is initialized
    var isInitialized: Bool {
        return db != nil && encryptionKey != nil
    }
}

enum DatabaseError: Error {
    case notInitialized
    case encryptionFailed
    case decryptionFailed
    case invalidData
}
