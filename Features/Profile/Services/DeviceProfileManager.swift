import Foundation
import Supabase
import UIKit

@MainActor
class DeviceProfileManager: ObservableObject {
    static let shared = DeviceProfileManager()
    
    @Published private(set) var currentProfile: DeviceProfile?
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
        
        Task {
            await ensureProfile()
        }
    }
    
    private func ensureProfile() async {
        guard let deviceId = UIDevice.current.identifierForVendor else { return }
        
        do {
            // Check if profile exists
            let profiles: [DeviceProfile] = try await supabase.database
                .from("device_profiles")
                .select()
                .eq("id", value: deviceId.uuidString)
                .execute()
                .value
            
            if let existingProfile = profiles.first {
                self.currentProfile = existingProfile
                // Update last_active
                try? await updateLastActive(deviceId: deviceId)
            } else {
                // Create new profile with direct SQL insert to bypass RLS
                let newProfile = DeviceProfile(
                    id: deviceId,
                    username: "user_\(String(deviceId.uuidString.prefix(8)))",
                    createdAt: Date()
                )
                
                try await supabase.database
                    .from("device_profiles")
                    .insert(newProfile, returning: .representation)
                    .select()
                    .single()
                    .execute()
                
                self.currentProfile = newProfile
            }
        } catch {
            print("Profile error: \(error)")
            // If insert failed, try one more time with a different username
            if self.currentProfile == nil {
                do {
                    let fallbackProfile = DeviceProfile(
                        id: deviceId,
                        username: "user_\(UUID().uuidString.prefix(8))",
                        createdAt: Date()
                    )
                    
                    try await supabase.database
                        .from("device_profiles")
                        .insert(fallbackProfile, returning: .representation)
                        .select()
                        .single()
                        .execute()
                    
                    self.currentProfile = fallbackProfile
                } catch {
                    print("Fallback profile creation failed: \(error)")
                }
            }
        }
    }
    
    private func updateLastActive(deviceId: UUID) async throws {
        try await supabase.database
            .from("device_profiles")
            .update(["last_active": Date()])
            .eq("id", value: deviceId.uuidString)
            .execute()
    }
}

struct DeviceProfile: Codable {
    let id: UUID
    let username: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
    }
} 
