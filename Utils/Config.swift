//
//  Config.swift
//  FoodDairy
//
//  Created by Sanat Dangol on 12/31/24.
//

import Foundation

enum Config {
    static let supabaseURL = URL(string: "https://dcgacsuoqmxzcwfuuhpj.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjZ2Fjc3VvcW14emN3ZnV1aHBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ4MTg4NDEsImV4cCI6MjA1MDM5NDg0MX0.Z0ySoY9t1kjZGrIMN14z3huN7ZkUh55frkK_rjLW-YA"
    
    // Network configuration
    static let networkTimeout: TimeInterval = 30
    static let retryAttempts = 3
    static let retryDelay: TimeInterval = 2
}
