import Foundation
import Network

extension URLRequest {
    func withMethod(_ method: String) -> URLRequest {
        var request = self
        request.httpMethod = method
        return request
    }
    
    func withHeaders(_ headers: [String: String]) -> URLRequest {
        var request = self
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
    
    func withBody(_ data: Data) -> URLRequest {
        var request = self
        request.httpBody = data
        return request
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private var activeConnections: Set<URLSessionTask> = []
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.fooddiary.network.monitor")
    private var isConnected = true
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: monitorQueue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    func getSupabaseHeaders() -> [String: String] {
        [
            "apikey": Config.supabaseAnonKey,
            "Authorization": "Bearer \(Config.supabaseAnonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }
    
    func request<T: Decodable>(_ endpoint: URL, method: String = "GET") async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = Config.networkTimeout
        
        // Add Supabase headers
        let headers = getSupabaseHeaders()
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return try await performRequest(request)
    }
    
    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        let task = URLSession.shared.dataTask(with: request)
        activeConnections.insert(task)
        defer { activeConnections.remove(task) }
        
        var lastError: Error?
        for attempt in 1...Config.retryAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    print("Unauthorized error - Headers sent: \(request.allHTTPHeaderFields ?? [:])")
                    print("Response headers: \(httpResponse.allHeaderFields)")
                    throw NetworkError.unauthorized
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("HTTP Error \(httpResponse.statusCode): \(errorString)")
                    }
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                lastError = error
                if attempt < Config.retryAttempts {
                    try await Task.sleep(nanoseconds: UInt64(Config.retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    func upload(_ data: Data, to endpoint: URL) async throws -> String {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = Config.networkTimeout
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: data)
        activeConnections.insert(task)
        defer { activeConnections.remove(task) }
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: responseData, encoding: .utf8) {
                throw NetworkError.uploadError(errorString)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("Upload response: \(responseString)")
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return uploadResponse.Key
    }
    
    func cancelAllTasks() {
        activeConnections.forEach { $0.cancel() }
        activeConnections.removeAll()
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case invalidResponse
    case httpError(Int)
    case uploadError(String)
    case cancelled
    case unknown
    case unauthorized
    case deviceIdNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .uploadError(let message):
            return "Upload failed: \(message)"
        case .cancelled:
            return "Operation was cancelled"
        case .unknown:
            return "Unknown network error"
        case .unauthorized:
            return "Please sign in to continue"
        case .deviceIdNotAvailable:
            return "Device ID not available"
        }
    }
}

struct UploadResponse: Codable {
    let Key: String
    
    // Custom coding keys to handle Supabase's response format
    private enum CodingKeys: String, CodingKey {
        case Key
    }
} 