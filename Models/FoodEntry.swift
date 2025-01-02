//
//  FoodEntry.swift
//  FoodDairy
//
//  Created by Sanat Dangol on 12/31/24.
//


import Foundation

struct FoodEntry: Identifiable, Codable {
    let id: UUID
    let deviceId: UUID
    let title: String
    let description: String?
    let photoURL: String
    let mealType: MealType
    let ingredients: [String]
    let dateCreated: Date      // When the entry was created
    let mealDate: Date         // When the meal was actually eaten
    
    enum CodingKeys: String, CodingKey {
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
    
    var imageURL: URL? {
        guard !photoURL.isEmpty else { return nil }
        if photoURL.hasPrefix("http"), let url = URL(string: photoURL) {
            return url
        }
        let baseURL = "\(Config.supabaseURL)/storage/v1/object/public/food-images"
        let encodedPath = photoURL.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? photoURL
        return URL(string: "\(baseURL)/\(encodedPath)")
    }
} 