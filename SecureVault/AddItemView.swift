//
//  AddItemView.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vaultManager: VaultManager

    @State private var selectedType: ItemType = .password
    @State private var title = ""

    // Password fields
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var passwordNotes = ""

    // Key fields
    @State private var key = ""
    @State private var keyType = "API Key"
    @State private var keyNotes = ""

    // Note fields
    @State private var noteContent = ""
    @State private var tags = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add New Item")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)

                Button("Save") {
                    saveItem()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || !isContentValid)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Type selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.headline)

                        Picker("Type", selection: $selectedType) {
                            ForEach(ItemType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        TextField("Enter title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Type-specific fields
                    switch selectedType {
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

    private var isContentValid: Bool {
        switch selectedType {
        case .password:
            return !password.isEmpty
        case .key:
            return !key.isEmpty
        case .note:
            return !noteContent.isEmpty
        }
    }

    private func saveItem() {
        let item: VaultItem

        switch selectedType {
        case .password:
            let passwordItem = PasswordItem(
                title: title,
                username: username,
                password: password,
                url: url,
                notes: passwordNotes
            )
            item = passwordItem.toVaultItem()

        case .key:
            let keyItem = KeyItem(
                title: title,
                key: key,
                keyType: keyType,
                notes: keyNotes
            )
            item = keyItem.toVaultItem()

        case .note:
            let noteItem = NoteItem(
                title: title,
                content: noteContent,
                tags: tags
            )
            item = noteItem.toVaultItem()
        }

        vaultManager.addItem(item)
        dismiss()
    }
}

struct PasswordFields: View {
    @Binding var username: String
    @Binding var password: String
    @Binding var url: String
    @Binding var notes: String

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                TextField("Enter username", text: $username)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                HStack {
                    if showPassword {
                        TextField("Enter password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                    .help(showPassword ? "Hide password" : "Show password")

                    Button("Generate") {
                        password = generatePassword()
                    }
                    .buttonStyle(.bordered)
                    .help("Generate random password")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.headline)
                TextField("Enter URL", text: $url)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .border(Color.gray.opacity(0.2))
            }
        }
    }

    private func generatePassword() -> String {
        let length = 16
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

struct KeyFields: View {
    @Binding var key: String
    @Binding var keyType: String
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Type")
                    .font(.headline)
                TextField("e.g., API Key, SSH Key, License", text: $keyType)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Key")
                    .font(.headline)
                TextEditor(text: $key)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))
                    .border(Color.gray.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .border(Color.gray.opacity(0.2))
            }
        }
    }
}

struct NoteFields: View {
    @Binding var content: String
    @Binding var tags: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                TextEditor(text: $content)
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                TextField("Separate with commas", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
