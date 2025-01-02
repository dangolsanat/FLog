import SwiftUI

struct FoodEntryListView: View {
    @StateObject private var foodEntryService = FoodEntryService()
    @EnvironmentObject var profileManager: DeviceProfileManager
    @State private var error: String?
    @State private var expandedPostId: UUID?
    @State private var isRefreshing = false
    @State private var showDeleteAlert = false
    @State private var entryToDelete: FoodEntry?
    @State private var showEditSheet = false
    @State private var entryToEdit: FoodEntry?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(foodEntryService.entries) { entry in
                    FoodEntryRow(entry: entry, isExpanded: expandedPostId == entry.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 6)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                entryToEdit = entry
                                showEditSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedPostId = expandedPostId == entry.id ? nil : entry.id
                            }
                        }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("flog-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                }
            }
            .refreshable {
                let task = Task {
                    try await foodEntryService.fetchEntries()
                }
                do {
                    try await task.value
                } catch is CancellationError {
                    // Ignore cancellation
                } catch {
                    self.error = error.localizedDescription
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let entry = entryToEdit {
                    EditFoodEntryView(entry: entry) { updatedEntry in
                        Task {
                            do {
                                try await foodEntryService.updateEntry(updatedEntry)
                                try await foodEntryService.fetchEntries()
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
                                try await foodEntryService.fetchEntries()
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
