import Foundation
import PhotosUI
import SwiftUI
import UIKit
import Supabase

public enum FeedType {
    case personal
    case all
    case random
    
    public var queryParams: [URLQueryItem] {
        switch self {
        case .personal:
            if let deviceId = UIDevice.current.identifierForVendor {
                return [
                    URLQueryItem(name: "device_id", value: "eq.\(deviceId.uuidString)"),
                    URLQueryItem(name: "order", value: "meal_date.desc")
                ]
            }
            return []
        case .all:
            return [
                URLQueryItem(name: "order", value: "meal_date.desc")
            ]
        case .random:
            return [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "20")
            ]
        }
    }
}

@MainActor
public class FoodEntryService: ObservableObject {
    @Published public private(set) var entries: [FoodEntry] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var uploadProgress: Double?
    
    private let imageUploadService: ImageUploadService
    private let feedType: FeedType
    private let supabase: SupabaseClient
    
    public init(feedType: FeedType = .personal) {
        self.imageUploadService = ImageUploadService(bucket: DatabaseConfig.foodImagesBucket)
        self.feedType = feedType
        self.supabase = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    @MainActor
    func fetchEntries(searchQuery: String? = nil) async throws {
        if feedType == .personal {
            let functionName = "get_device_feed"
            guard let deviceId = UUID(uuidString: UIDevice.current.identifierForVendor?.uuidString ?? "") else {
                throw NetworkError.deviceIdNotAvailable
            }
            
            if let searchQuery = searchQuery {
                // Use the two-parameter version when search query is provided
                struct RPCParams: Encodable {
                    let target_device_id: UUID
                    let search_query: String
                }
                
                let params = RPCParams(
                    target_device_id: deviceId,
                    search_query: searchQuery
                )
                
                let response: [FoodEntry] = try await supabase.database
                    .rpc(functionName, params: params)
                    .execute()
                    .value
                
                entries = response
            } else {
                // Use the single-parameter version when no search query
                struct RPCParams: Encodable {
                    let target_device_id: UUID
                }
                
                let params = RPCParams(
                    target_device_id: deviceId
                )
                
                let response: [FoodEntry] = try await supabase.database
                    .rpc(functionName, params: params)
                    .execute()
                    .value
                
                entries = response
            }
        } else if feedType == .random {
            let response: [FoodEntry] = try await supabase.database
                .from("food_entries")
                .select()
                .order("RANDOM()")
                .limit(1)
                .execute()
                .value
            entries = response
        } else {
            let response: [FoodEntry] = try await supabase.database
                .from("food_entries")
                .select()
                .order("meal_date", ascending: false)
                .execute()
                .value
            entries = response
        }
    }
    
    @MainActor
    func createEntry(_ entry: FoodEntry) async throws {
        let response: FoodEntry = try await supabase.database
            .from("food_entries")
            .insert(entry)
            .select()
            .single()
            .execute()
            .value
        
        entries.insert(response, at: 0)
    }
    
    @MainActor
    func updateEntry(_ entry: FoodEntry) async throws {
        let response: FoodEntry = try await supabase.database
            .from("food_entries")
            .update(entry)
            .eq("id", value: entry.id)
            .select()
            .single()
            .execute()
            .value
        
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = response
        }
    }
    
    @MainActor
    func deleteEntry(_ entry: FoodEntry) async throws {
        try await supabase.database
            .from("food_entries")
            .delete()
            .eq("id", value: entry.id)
            .execute()
        
        entries.removeAll { $0.id == entry.id }
    }
    
    public func addEntry(
        title: String,
        description: String,
        mealType: FoodEntry.MealType,
        ingredients: [String],
        photo: PhotosPickerItem?,
        mealDate: Date
    ) async throws {
        isLoading = true
        defer {
            isLoading = false
            uploadProgress = nil
        }
        
        guard let deviceId = UIDevice.current.identifierForVendor else {
            throw NetworkError.deviceIdNotAvailable
        }
        
        do {
            var photoURL = ""
            if let photo = photo {
                uploadProgress = 0.0
                
                guard let imageData = try await photo.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: imageData),
                      let processedImageData = ImageProcessor.processForUpload(uiImage) else {
                    throw NetworkError.invalidResponse
                }
                
                // Simulate upload progress
                for progress in stride(from: 0.0, to: 0.9, by: 0.1) {
                    uploadProgress = progress
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
                
                photoURL = try await imageUploadService.uploadImage(processedImageData)
                uploadProgress = 1.0
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            // Filter out empty ingredients and ensure array is not empty
            print("DEBUG: Service - Original ingredients count: \(ingredients.count)")
            print("DEBUG: Service - Original ingredients: \(ingredients)")
            
            // Trim whitespace and filter out empty ingredients
            let filteredIngredients = ingredients.map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            print("DEBUG: Service - Filtered ingredients count: \(filteredIngredients.count)")
            print("DEBUG: Service - Filtered ingredients: \(filteredIngredients)")
            
            // Ensure we always have at least one ingredient, even if empty
            let finalIngredients = filteredIngredients.isEmpty ? [""] : filteredIngredients
            print("DEBUG: Service - Final ingredients count: \(finalIngredients.count)")
            print("DEBUG: Service - Final ingredients: \(finalIngredients)")
            
            let newEntry = FoodEntry(
                id: UUID(),
                deviceId: deviceId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                photoURL: photoURL.isEmpty ? nil : photoURL,
                mealType: mealType,
                ingredients: finalIngredients,
                dateCreated: Date(),
                mealDate: mealDate
            )
            
            print("DEBUG: About to insert entry with ingredients: \(newEntry.ingredients)")
            
            // Create the entry in the database
            let response: FoodEntry = try await supabase.database
                .from("food_entries")
                .insert(newEntry)
                .select()
                .single()
                .execute()
                .value
            
            print("DEBUG: Successfully inserted entry, response ingredients: \(response.ingredients)")
            
            // Update local state
            if feedType == .personal {
                print("DEBUG: Current entries count before insert: \(entries.count)")
                print("DEBUG: Attempting to insert at index 0")
                
                // Create a new array instead of modifying in place
                var updatedEntries = entries
                updatedEntries.insert(response, at: 0)
                print("DEBUG: Entries count after insert: \(updatedEntries.count)")
                
                // Sort the new array
                updatedEntries.sort { $0.mealDate > $1.mealDate }
                print("DEBUG: Entries count after sort: \(updatedEntries.count)")
                
                // Update the published array
                entries = updatedEntries
                print("DEBUG: Final entries count: \(entries.count)")
            }
        } catch is CancellationError {
            print("Add entry task was cancelled")
            throw NetworkError.cancelled
        }
    }
    
    private func sortEntries() {
        entries.sort { $0.mealDate > $1.mealDate }
    }
    
    deinit {
        NetworkManager.shared.cancelAllTasks()
    }
}

struct EmptyResponse: Codable {} 
