import Foundation
import UIKit

@MainActor
public class ImageUploadService: ImageUploaderProtocol {
    private let bucket: String
    private let networkManager = NetworkManager.shared
    
    public init(bucket: String) {
        self.bucket = bucket
    }
    
    public func uploadImage(_ imageData: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(bucket)/\(fileName)"
        
        // Create URL for storage upload
        let urlComponents = URLComponents(url: Config.supabaseURL.appendingPathComponent("storage/v1/object/\(path)"), resolvingAgainstBaseURL: true)!
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidResponse
        }
        
        // Create upload request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        
        // Add headers
        let headers = networkManager.getSupabaseHeaders()
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        // Upload image
        let _: EmptyResponse = try await networkManager.performRequest(request)
        
        // Return the public URL
        return "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/\(path)"
    }
} 