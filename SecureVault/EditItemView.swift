//
//  EditItemView.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vaultManager: VaultManager

    let item: VaultItem

    @State private var title: String
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var passwordNotes = ""
    @State private var key = ""
    @State private var keyType = ""
    @State private var keyNotes = ""
    @State private var noteContent = ""
    @State private var tags = ""

    init(item: VaultItem) {
        self.item = item
        _title = State(initialValue: item.title)

        switch item.type {
        case .password:
            if let passwordItem = PasswordItem.fromVaultItem(item) {
                _username = State(initialValue: passwordItem.username)
                _password = State(initialValue: passwordItem.password)
                _url = State(initialValue: passwordItem.url)
                _passwordNotes = State(initialValue: passwordItem.notes)
            }
        case .key:
            if let keyItem = KeyItem.fromVaultItem(item) {
                _key = State(initialValue: keyItem.key)
                _keyType = State(initialValue: keyItem.keyType)
                _keyNotes = State(initialValue: keyItem.notes)
            }
        case .note:
            if let noteItem = NoteItem.fromVaultItem(item) {
                _noteContent = State(initialValue: noteItem.content)
                _tags = State(initialValue: noteItem.tags)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Item")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)

                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        TextField("Enter title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    switch item.type {
                    case .password:
                        PasswordFields(
                            username: $username,
                            password: $password,
                            url: $url,
                            notes: $passwordNotes
                        )
                    case .key:
                        KeyFields(
                            key: $key,
                            keyType: $keyType,
                            notes: $keyNotes
                        )
                    case .note:
                        NoteFields(
                            content: $noteContent,
                            tags: $tags
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }

    private func saveChanges() {
        var updatedItem = item
        updatedItem.title = title

        switch item.type {
        case .password:
            let passwordItem = PasswordItem(
                title: title,
                username: username,
                password: password,
                url: url,
                notes: passwordNotes
            )
            updatedItem = passwordItem.toVaultItem()
            updatedItem.id = item.id
            updatedItem.createdAt = item.createdAt
            updatedItem.isFavorite = item.isFavorite

        case .key:
            let keyItem = KeyItem(
                title: title,
                key: key,
                keyType: keyType,
                notes: keyNotes
            )
            updatedItem = keyItem.toVaultItem()
            updatedItem.id = item.id
            updatedItem.createdAt = item.createdAt
            updatedItem.isFavorite = item.isFavorite

        case .note:
            let noteItem = NoteItem(
                title: title,
                content: noteContent,
                tags: tags
            )
            updatedItem = noteItem.toVaultItem()
            updatedItem.id = item.id
            updatedItem.createdAt = item.createdAt
            updatedItem.isFavorite = item.isFavorite
        }

        vaultManager.updateItem(updatedItem)
        dismiss()
    }
}
