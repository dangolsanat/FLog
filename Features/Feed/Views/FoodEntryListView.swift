import SwiftUI

struct FoodEntryListView: View {
    @StateObject private var foodEntryService = FoodEntryService()
    @EnvironmentObject var profileManager: DeviceProfileManager
    @State private var error: String?
    @State private var expandedPostId: UUID?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(foodEntryService.entries) { entry in
                        FoodEntryRow(entry: entry, isExpanded: expandedPostId == entry.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    expandedPostId = expandedPostId == entry.id ? nil : entry.id
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .navigationTitle("Food Diary")
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
