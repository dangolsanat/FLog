import Foundation

public enum ImageUploadError: LocalizedError {
    case invalidImageData
    case uploadFailed(Error)
    case invalidResponse
    case serverError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
} 