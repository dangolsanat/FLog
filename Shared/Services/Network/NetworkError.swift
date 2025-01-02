import Foundation

public enum NetworkError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case deviceIdNotAvailable
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .deviceIdNotAvailable:
            return "Device ID not available"
        case .cancelled:
            return "Request was cancelled"
        }
    }
} 