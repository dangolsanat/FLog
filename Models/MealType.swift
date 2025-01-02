//
//  MealType.swift
//  FoodDairy
//
//  Created by Sanat Dangol on 12/31/24.
//


import Foundation

// Single source of truth for MealType
enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case brunch = "brunch"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
} 