import Foundation
import PhotosUI
import SwiftUI
import UIKit

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
    
    public init(feedType: FeedType = .personal) {
        self.imageUploadService = ImageUploadService(bucket: DatabaseConfig.foodImagesBucket)
        self.feedType = feedType
    }
    
    public func fetchEntries() async throws {
        isLoading = true
        defer { isLoading = false }
        
        var urlComponents = URLComponents(url: Config.supabaseURL.appendingPathComponent("rest/v1/food_entries"), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = feedType.queryParams
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidResponse
        }
        
        let entries: [FoodEntry] = try await NetworkManager.shared.request(url)
        self.entries = entries
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
            
            let newEntry = FoodEntry(
                id: UUID(),
                deviceId: deviceId,
                title: title,
                description: description,
                photoURL: photoURL,
                mealType: mealType,
                ingredients: ingredients.filter { !$0.isEmpty },
                dateCreated: Date(),
                mealDate: mealDate
            )
            
            // Create the entry in the database
            let urlComponents = URLComponents(url: Config.supabaseURL.appendingPathComponent("rest/v1/food_entries"), resolvingAgainstBaseURL: true)!
            guard let url = urlComponents.url else {
                throw NetworkError.invalidResponse
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try encoder.encode(newEntry)
            
            // Add Supabase headers
            let headers = NetworkManager.shared.getSupabaseHeaders()
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            
            let _: EmptyResponse = try await NetworkManager.shared.performRequest(request)
            
            // Update local state
            if feedType == .personal {
                entries.insert(newEntry, at: 0)
                sortEntries()
            }
        } catch is CancellationError {
            print("Add entry task was cancelled")
            throw NetworkError.cancelled
        }
    }
    
    private func sortEntries() {
        entries.sort { $0.mealDate > $1.mealDate }
    }
    
    public func deleteEntry(_ entry: FoodEntry) async throws {
        let urlComponents = URLComponents(url: Config.supabaseURL.appendingPathComponent("rest/v1/food_entries"), resolvingAgainstBaseURL: true)!
        var components = urlComponents
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(entry.id)")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add Supabase headers
        let headers = NetworkManager.shared.getSupabaseHeaders()
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let _: EmptyResponse = try await NetworkManager.shared.performRequest(request)
        
        // Update local state
        if feedType == .personal {
            entries.removeAll { $0.id == entry.id }
        }
    }
    
    public func updateEntry(_ entry: FoodEntry) async throws {
        let urlComponents = URLComponents(url: Config.supabaseURL.appendingPathComponent("rest/v1/food_entries"), resolvingAgainstBaseURL: true)!
        var components = urlComponents
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(entry.id)")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(entry)
        
        // Add Supabase headers
        let headers = NetworkManager.shared.getSupabaseHeaders()
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let _: EmptyResponse = try await NetworkManager.shared.performRequest(request)
        
        // Update local state
        if feedType == .personal {
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = entry
                sortEntries()
            }
        }
    }
    
    deinit {
        NetworkManager.shared.cancelAllTasks()
    }
}

struct EmptyResponse: Codable {} 
