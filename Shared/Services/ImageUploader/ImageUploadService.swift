import Foundation

enum ImageUploadError: Error, LocalizedError {
    case invalidImageData
    case uploadFailed(Error)
    case invalidResponse
    case serverError(Int, String)
    
    var errorDescription: String? {
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

@MainActor
class ImageUploadService: ImageUploader {
    private let storageURL: URL
    private let bucket: String
    private let networkManager = NetworkManager.shared
    
    init(bucket: String) {
        self.bucket = bucket
        self.storageURL = Config.supabaseURL.appendingPathComponent("storage/v1/object")
    }
    
    func uploadImage(_ imageData: Data) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let url = storageURL.appendingPathComponent(bucket).appendingPathComponent(filename)
        
        print("Uploading to URL: \(url.absoluteString)")
        
        do {
            let key = try await networkManager.upload(imageData, to: url)
            // Fix: Use the correct public URL format for Supabase storage
            let publicURL = "\(Config.supabaseURL.absoluteString)/storage/v1/object/public/\(bucket)/\(filename)"
            print("Upload successful: \(publicURL)")
            return publicURL
        } catch {
            print("Upload failed: \(error)")
            throw error
        }
    }
} 