import SwiftUI

@main
struct FoodDairyApp: App {
    @StateObject private var profileManager = DeviceProfileManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(profileManager)
        }
    }
} 