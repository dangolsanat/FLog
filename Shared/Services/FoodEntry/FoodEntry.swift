import Foundation

public struct FoodEntry: Identifiable, Codable {
    public enum MealType: String, Codable, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snack = "snack"
    }
    
    public let id: UUID
    public let deviceId: UUID
    public let title: String
    public let description: String?
    public let photoURL: String?
    public let mealType: MealType
    public let ingredients: [String]
    public let dateCreated: Date
    public let mealDate: Date
    
    public init(
        id: UUID,
        deviceId: UUID,
        title: String,
        description: String?,
        photoURL: String?,
        mealType: MealType,
        ingredients: [String],
        dateCreated: Date,
        mealDate: Date
    ) {
        self.id = id
        self.deviceId = deviceId
        self.title = title
        self.description = description
        self.photoURL = photoURL
        self.mealType = mealType
        self.ingredients = ingredients
        self.dateCreated = dateCreated
        self.mealDate = mealDate
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case title
        case description
        case photoURL = "photo_url"
        case mealType = "meal_type"
        case ingredients
        case dateCreated = "created_at"
        case mealDate = "meal_date"
    }
} 