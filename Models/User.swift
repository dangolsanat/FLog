//
//  User.swift
//  FoodDairy
//
//  Created by Sanat Dangol on 12/31/24.
//


import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let username: String
    let passwordHash: String
    let createdAt: Date
    let profileImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case passwordHash = "password_hash"
        case createdAt = "created_at"
        case profileImageURL = "profile_image_url"
    }
    
    var profileImageFullURL: URL? {
        guard let profileImageURL = profileImageURL, !profileImageURL.isEmpty else { return nil }
        if profileImageURL.hasPrefix("http"), let url = URL(string: profileImageURL) {
            return url
        }
        let baseURL = "\(Config.supabaseURL)/storage/v1/object/public/profile-images"
        let encodedPath = profileImageURL.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? profileImageURL
        return URL(string: "\(baseURL)/\(encodedPath)")
    }
} 
