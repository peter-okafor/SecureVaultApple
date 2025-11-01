import Foundation

// MARK: - Item Type Enum
enum ItemType: String, Codable, CaseIterable {
    case password = "Password"
    case key = "Key"
    case note = "Note"

    var icon: String {
        switch self {
        case .password: return "key.fill"
        case .key: return "link.circle.fill"
        case .note: return "note.text"
        }
    }
}

// MARK: - Vault Item
struct VaultItem: Identifiable, Codable, Hashable {
    var id: UUID
    var type: ItemType
    var title: String
    var content: String
    var metadata: [String: String]
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        type: ItemType,
        title: String,
        content: String,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.metadata = metadata
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isFavorite = isFavorite
    }
}

// MARK: - Password Item
struct PasswordItem {
    var title: String
    var username: String
    var password: String
    var url: String
    var notes: String

    func toVaultItem() -> VaultItem {
        let metadata: [String: String] = [
            "username": username,
            "url": url,
            "notes": notes
        ]
        return VaultItem(
            type: .password,
            title: title,
            content: password,
            metadata: metadata
        )
    }

    static func fromVaultItem(_ item: VaultItem) -> PasswordItem? {
        guard item.type == .password else { return nil }
        return PasswordItem(
            title: item.title,
            username: item.metadata["username"] ?? "",
            password: item.content,
            url: item.metadata["url"] ?? "",
            notes: item.metadata["notes"] ?? ""
        )
    }
}

// MARK: - Key Item
struct KeyItem {
    var title: String
    var key: String
    var keyType: String
    var notes: String

    func toVaultItem() -> VaultItem {
        let metadata: [String: String] = [
            "keyType": keyType,
            "notes": notes
        ]
        return VaultItem(
            type: .key,
            title: title,
            content: key,
            metadata: metadata
        )
    }

    static func fromVaultItem(_ item: VaultItem) -> KeyItem? {
        guard item.type == .key else { return nil }
        return KeyItem(
            title: item.title,
            key: item.content,
            keyType: item.metadata["keyType"] ?? "Generic",
            notes: item.metadata["notes"] ?? ""
        )
    }
}

// MARK: - Note Item
struct NoteItem {
    var title: String
    var content: String
    var tags: String

    func toVaultItem() -> VaultItem {
        let metadata: [String: String] = [
            "tags": tags
        ]
        return VaultItem(
            type: .note,
            title: title,
            content: content,
            metadata: metadata
        )
    }

    static func fromVaultItem(_ item: VaultItem) -> NoteItem? {
        guard item.type == .note else { return nil }
        return NoteItem(
            title: item.title,
            content: item.content,
            tags: item.metadata["tags"] ?? ""
        )
    }
}
