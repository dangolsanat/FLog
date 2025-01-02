import Foundation

public protocol ImageUploaderProtocol {
    func uploadImage(_ imageData: Data) async throws -> String
} 