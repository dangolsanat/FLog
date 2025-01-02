import Foundation
import UIKit

public class NetworkManager {
    public static let shared = NetworkManager()
    
    private init() {}
    
    public func getSupabaseHeaders() -> [String: String] {
        var headers = [
            "apikey": Config.supabaseAnonKey,
            "Authorization": "Bearer \(Config.supabaseAnonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
        ]
        
        // Add device ID header
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            headers["x-device-id"] = deviceId
        }
        
        return headers
    }
    
    public func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        let headers = getSupabaseHeaders()
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await performRequest(request)
    }
    
    public func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    public func cancelAllTasks() {
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
} 