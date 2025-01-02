import SwiftUI

private struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var tabSelection: Binding<Int> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var foodEntryService = FoodEntryService()
    @StateObject private var profileManager = DeviceProfileManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FoodEntryListView()
                .environmentObject(foodEntryService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AllUserFeedView()
                .tabItem {
                    Label("All Feed", systemImage: "list.bullet")
                }
                .tag(1)
            
            AddFoodEntryView(foodEntryService: foodEntryService)
                .tabItem {
                    Label("New Post", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            RandomFeedView()
                .tabItem {
                    Label("Random", systemImage: "shuffle")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .environment(\.tabSelection, $selectedTab)
        .environmentObject(profileManager)
        .background(Color(uiColor: .systemBackground))
        .accentColor(.blue)
    }
}

struct AllUserFeedView: View {
    @StateObject private var foodEntryService = FoodEntryService(feedType: .all)
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
            .navigationTitle("All Feeds")
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

struct RandomFeedView: View {
    @StateObject private var foodEntryService = FoodEntryService(feedType: .random)
    @State private var error: String?
    @State private var currentRandomEntry: FoodEntry?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    if let entry = currentRandomEntry {
                        FoodEntryRow(entry: entry, isExpanded: true)
                        
                        Text("Pull down to shuffle")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .navigationTitle("Random Feed")
            .refreshable {
                let task = Task {
                    await shuffleEntry()
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
            await shuffleEntry()
        }
    }
    
    private func shuffleEntry() async {
        do {
            try await foodEntryService.fetchEntries()
            if let randomEntry = foodEntryService.entries.randomElement() {
                withAnimation {
                    currentRandomEntry = randomEntry
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    
    MainTabView()
        .environmentObject(DeviceProfileManager.shared)
}
