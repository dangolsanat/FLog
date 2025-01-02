import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileManager: DeviceProfileManager
    
    var body: some View {
        NavigationView {
            VStack {
                if let profile = profileManager.currentProfile {
                    Text("Username: \(profile.username)")
                        .padding()
                    
                    Text("Device ID: \(profile.id)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Profile")
        }
    }
} 