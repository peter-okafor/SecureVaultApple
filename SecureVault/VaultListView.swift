//
//  VaultListView.swift
//  SecureVault
//
//  Created by Peter Okafor on 01/11/2025.
//

import SwiftUI
import AppKit

struct VaultListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var vaultManager: VaultManager

    @State private var searchText = ""
    @State private var selectedType: ItemType?
    @State private var selectedItem: VaultItem?
    @State private var showingAddItem = false
    @State private var addItemWindow: NSWindow?

    var filteredItems: [VaultItem] {
        var items = vaultManager.items

        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let type = selectedType {
            items = items.filter { $0.type == type }
        }

        return items.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SecureVault")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: { openAddItemWindow() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Button(action: { authManager.lock() }) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)

                // Filter tabs
                HStack(spacing: 4) {
                    FilterTab(title: "All", isSelected: selectedType == nil) {
                        selectedType = nil
                    }

                    ForEach(ItemType.allCases, id: \.self) { type in
                        FilterTab(
                            title: type.rawValue,
                            icon: type.icon,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)

                Divider()

                // Items list
                if vaultManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No items found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredItems, selection: $selectedItem) { item in
                        ItemRow(item: item)
                            .tag(item)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 300)
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                VStack {
                    Image(systemName: "lock.doc")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select an item")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func openAddItemWindow() {
        let contentView = AddItemView()
            .environmentObject(vaultManager)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Add New Item"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 600, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating

        addItemWindow = window
    }
}

struct FilterTab: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ItemRow: View {
    let item: VaultItem

    var body: some View {
        HStack {
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
