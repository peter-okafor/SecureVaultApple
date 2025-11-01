import SwiftUI
import AppKit

struct ItemDetailView: View {
    @EnvironmentObject var vaultManager: VaultManager
    let item: VaultItem

    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var editItemWindow: NSWindow?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: item.type.icon)
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(item.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { vaultManager.toggleFavorite(item) }) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundColor(item.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(.plain)

                Button(action: { openEditItemWindow() }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch item.type {
                    case .password:
                        if let passwordItem = PasswordItem.fromVaultItem(item) {
                            PasswordDetailContent(item: passwordItem)
                        }
                    case .key:
                        if let keyItem = KeyItem.fromVaultItem(item) {
                            KeyDetailContent(item: keyItem)
                        }
                    case .note:
                        if let noteItem = NoteItem.fromVaultItem(item) {
                            NoteDetailContent(item: noteItem)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Created", value: formatDate(item.createdAt))
                        DetailRow(label: "Modified", value: formatDate(item.modifiedAt))
                    }
                }
                .padding()
            }
        }
        .alert("Delete Item", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vaultManager.deleteItem(item)
            }
        } message: {
            Text("Are you sure you want to delete \"\(item.title)\"? This action cannot be undone.")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openEditItemWindow() {
        let contentView = EditItemView(item: item)
            .environmentObject(vaultManager)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Edit Item"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 600, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        editItemWindow = window
    }
}

struct PasswordDetailContent: View {
    let item: PasswordItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !item.username.isEmpty {
                CopyableField(label: "Username", value: item.username)
            }

            CopyableField(label: "Password", value: item.password, isSecret: true)

            if !item.url.isEmpty {
                DetailRow(label: "URL", value: item.url)
            }

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.notes)
                }
            }
        }
    }
}

struct KeyDetailContent: View {
    let item: KeyItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(label: "Type", value: item.keyType)

            CopyableField(label: "Key", value: item.key, isSecret: true, isMultiline: true)

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.notes)
                }
            }
        }
    }
}

struct NoteDetailContent: View {
    let item: NoteItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !item.tags.isEmpty {
                DetailRow(label: "Tags", value: item.tags)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.content)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
        }
    }
}

struct CopyableField: View {
    let label: String
    let value: String
    var isSecret: Bool = false
    var isMultiline: Bool = false

    @State private var isRevealed = false
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                if isSecret && !isRevealed {
                    Text(String(repeating: "•", count: 12))
                        .font(.system(.body, design: .monospaced))
                } else {
                    if isMultiline {
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text(value)
                            .textSelection(.enabled)
                    }
                }

                Spacer()

                if isSecret {
                    Button(action: { isRevealed.toggle() }) {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                Button(action: copyToClipboard) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(showCopied ? .green : .blue)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)

        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}
