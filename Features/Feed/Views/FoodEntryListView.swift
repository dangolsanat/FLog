import SwiftUI

struct SearchHeader: View {
    @Binding var searchText: String
    var onSearch: (String?) async throws -> Void
    @Binding var isSearching: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search food, ingredients...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .onChange(of: searchText) { newValue in
                        isSearching = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            if searchText == newValue {
                                try await onSearch(newValue.isEmpty ? nil : newValue)
                                isSearching = false
                            }
                        }
                    }
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            try await onSearch(nil)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(white: 0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black)
    }
}

struct FoodEntryListView: View {
    @StateObject private var foodEntryService = FoodEntryService()
    @EnvironmentObject var profileManager: DeviceProfileManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var error: String?
    @State private var expandedPostId: UUID?
    @State private var isRefreshing = false
    @State private var showDeleteAlert = false
    @State private var entryToDelete: FoodEntry?
    @State private var entryToEdit: FoodEntry?
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchHeader(
                    searchText: $searchText,
                    onSearch: { query in
                        try await foodEntryService.fetchEntries(searchQuery: query)
                    },
                    isSearching: $isSearching
                )
                
                List {
                    if isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(foodEntryService.entries) { entry in
                            FoodEntryRow(entry: entry, isExpanded: expandedPostId == entry.id)
                                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    expandedPostId = expandedPostId == entry.id ? nil : entry.id
                                }
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: expandedPostId)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        entryToDelete = entry
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        entryToEdit = entry
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(Color(colorScheme == .dark ? .systemBackground : .systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .refreshable {
                do {
                    try await foodEntryService.fetchEntries(searchQuery: searchText.isEmpty ? nil : searchText)
                } catch is CancellationError {
                    // Ignore cancellation
                } catch {
                    self.error = error.localizedDescription
                }
            }
            .sheet(item: $entryToEdit) { entry in
                NavigationView {
                    EditFoodEntryView(entry: entry) { updatedEntry in
                        Task {
                            do {
                                try await foodEntryService.updateEntry(updatedEntry)
                                try await foodEntryService.fetchEntries(searchQuery: searchText.isEmpty ? nil : searchText)
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        Task {
                            do {
                                try await foodEntryService.deleteEntry(entry)
                                try await foodEntryService.fetchEntries(searchQuery: searchText.isEmpty ? nil : searchText)
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this post?")
            }
            .alert("Error", isPresented: .constant(error != nil), actions: {
                Button("OK") { error = nil }
            }, message: {
                Text(error ?? "Unknown error")
            })
        }
        .task {
            do {
                try await foodEntryService.fetchEntries()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    FoodEntryListView()
        .environmentObject(DeviceProfileManager.shared)
} 
