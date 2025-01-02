import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    let isExpanded: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background image
                if let url = URL(string: entry.photoURL ?? "") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: isExpanded ? 300 : 120)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: isExpanded ? 300 : 120)
                }
                
                // Dark overlay
                Color.black.opacity(colorScheme == .dark ? 0.6 : 0.4)
                
                // Content
                HStack(alignment: .top, spacing: 12) {
                    // Left side: Title and Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let description = entry.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        if isExpanded {
                            // Extended info
                            VStack(alignment: .leading, spacing: 8) {
                                if !entry.ingredients.isEmpty {
                                    Text("Ingredients")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                    ForEach(entry.ingredients, id: \.self) { ingredient in
                                        Text("• \(ingredient)")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                
                                Text(entry.mealType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(colorScheme == .dark ? 0.5 : 0.7))
                                    .clipShape(Capsule())
                                    .padding(.top, 4)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    Spacer(minLength: 16)
                    
                    // Right side: Calendar style date
                    if !isExpanded {
                        VStack(alignment: .center, spacing: 0) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(entry.dateCreated.formatted(.dateTime.day()))")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.dateCreated.formatted(.dateTime.month(.abbreviated)))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Text(entry.dateCreated.formatted(.dateTime.year()))
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(entry.dateCreated.formatted(.dateTime.weekday(.abbreviated)))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 2)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(colorScheme == .dark ? 0.4 : 0.3))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(12)
            }
            .frame(height: isExpanded ? 300 : 120, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(Color(colorScheme == .dark ? .systemGray6 : .systemBackground))
        }
        .frame(height: isExpanded ? 300 : 120)
    }
}

#Preview {
    Group {
        VStack(spacing: 8) {
            FoodEntryRow(
                entry: FoodEntry(
                    id: UUID(),
                    deviceId: UUID(),
                    title: "Morning Oatmeal",
                    description: "Steel cut oats with berries and honey",
                    photoURL: "https://hikarimiso.com/wp-content/uploads/2024/05/Trimmed_03_Miso-Ramen_02_M.jpg.webp",
                    mealType: .breakfast,
                    ingredients: ["Oats", "Berries", "Honey"],
                    dateCreated: Date(),
                    mealDate: Date()
                ),
                isExpanded: false
            )
            
            FoodEntryRow(
                entry: FoodEntry(
                    id: UUID(),
                    deviceId: UUID(),
                    title: "Lunch Ramen",
                    description: "Spicy miso ramen with extra noodles",
                    photoURL: "https://hikarimiso.com/wp-content/uploads/2024/05/Trimmed_03_Miso-Ramen_02_M.jpg.webp",
                    mealType: .lunch,
                    ingredients: ["Noodles", "Miso", "Egg"],
                    dateCreated: Date(),
                    mealDate: Date()
                ),
                isExpanded: true
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .preferredColorScheme(.light)
        
        VStack(spacing: 8) {
            FoodEntryRow(
                entry: FoodEntry(
                    id: UUID(),
                    deviceId: UUID(),
                    title: "Morning Oatmeal",
                    description: "Steel cut oats with berries and honey",
                    photoURL: "https://hikarimiso.com/wp-content/uploads/2024/05/Trimmed_03_Miso-Ramen_02_M.jpg.webp",
                    mealType: .breakfast,
                    ingredients: ["Oats", "Berries", "Honey"],
                    dateCreated: Date(),
                    mealDate: Date()
                ),
                isExpanded: false
            )
            
            FoodEntryRow(
                entry: FoodEntry(
                    id: UUID(),
                    deviceId: UUID(),
                    title: "Lunch Ramen",
                    description: "Spicy miso ramen with extra noodles",
                    photoURL: "https://hikarimiso.com/wp-content/uploads/2024/05/Trimmed_03_Miso-Ramen_02_M.jpg.webp",
                    mealType: .lunch,
                    ingredients: ["Noodles", "Miso", "Egg"],
                    dateCreated: Date(),
                    mealDate: Date()
                ),
                isExpanded: true
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark)
    }
} 
