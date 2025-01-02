import Foundation

@MainActor
protocol ImageUploader {
    func uploadImage(_ imageData: Data) async throws -> String
} 