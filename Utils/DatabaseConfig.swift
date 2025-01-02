import Foundation

enum DatabaseConfig {
    // Storage Buckets
    static let foodImagesBucket = "food-images"
    
    // Tables
    static let profilesTable = "profiles"
    static let foodEntriesTable = "food_entries"
    static let followsTable = "follows"
    
    // Schemas
    static let publicSchema = "public"
    static let storageSchema = "storage"
    
    // Other configurations
    static let maxUploadSize = 5 * 1024 * 1024 // 5MB in bytes
} 