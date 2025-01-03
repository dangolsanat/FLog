import SwiftUI
import PhotosUI

struct AddFoodEntryView: View {
    @ObservedObject var foodEntryService: FoodEntryService
    @Environment(\.tabSelection) var tabSelection
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedMealType = FoodEntry.MealType.breakfast
    @State private var ingredients: [String] = [""]
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedDate = Date()
    @StateObject private var imageViewModel = ImageViewModel()
    
    private func resetForm() {
        title = ""
        description = ""
        selectedMealType = .breakfast
        ingredients = [""]
        selectedPhoto = nil
        selectedDate = Date()
        imageViewModel.selectedImage = nil
    }
    
    var body: some View {
        NavigationView {
            AddFoodEntryFormView(
                title: $title,
                description: $description,
                selectedMealType: $selectedMealType,
                ingredients: $ingredients,
                selectedPhoto: $selectedPhoto,
                selectedDate: $selectedDate,
                imageViewModel: imageViewModel,
                uploadProgress: foodEntryService.uploadProgress,
                onSave: {
                    Task {
                        do {
                            print("DEBUG: Saving with ingredients count: \(ingredients.count)")
                            print("DEBUG: Ingredients content: \(ingredients)")
                            
                            // Create a local copy of the ingredients
                            let ingredientsCopy = ingredients
                            
                            try await foodEntryService.addEntry(
                                title: title,
                                description: description,
                                mealType: selectedMealType,
                                ingredients: ingredientsCopy,
                                photo: selectedPhoto,
                                mealDate: selectedDate
                            )
                            
                            // Reset form on the main thread
                            await MainActor.run {
                                resetForm()
                                // Switch to home tab
                                tabSelection.wrappedValue = 0
                            }
                        } catch {
                            print("Error saving entry: \(error.localizedDescription)")
                        }
                    }
                },
                isLoading: foodEntryService.isLoading
            )
        }
    }
}

struct AddFoodEntryFormView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedMealType: FoodEntry.MealType
    @Binding var ingredients: [String]
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedDate: Date
    @ObservedObject var imageViewModel: AddFoodEntryView.ImageViewModel
    let uploadProgress: Double?
    let onSave: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Form {
            BasicInfoSection(
                title: $title,
                description: $description,
                selectedMealType: $selectedMealType,
                selectedDate: $selectedDate
            )
            
            IngredientsSection(ingredients: $ingredients)
            
            PhotoSection(
                selectedPhoto: $selectedPhoto,
                imageViewModel: imageViewModel
            )
            
            if let progress = uploadProgress {
                ProgressSection(progress: progress)
            }
        }
        .navigationTitle("Add Food Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: onSave)
                    .disabled(title.isEmpty || isLoading)
            }
        }
    }
}

private struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedMealType: FoodEntry.MealType
    @Binding var selectedDate: Date
    
    var body: some View {
        Section("Basic Info") {
            TextField("Title", text: $title)
            TextField("Description", text: $description)
            Picker("Meal Type", selection: $selectedMealType) {
                ForEach(FoodEntry.MealType.allCases, id: \.self) { mealType in
                    Text(mealType.rawValue.capitalized)
                }
            }
            
            DatePicker(
                "Meal Date",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
}

private struct IngredientsSection: View {
    @Binding var ingredients: [String]
    
    var body: some View {
        Section("Ingredients") {
            ForEach($ingredients.indices, id: \.self) { index in
                let _ = print("DEBUG: Rendering ingredient at index \(index), total count: \(ingredients.count)")
                TextField("Ingredient \(index + 1)", text: $ingredients[index])
            }
            .onDelete { indices in
                print("DEBUG: Before deletion - ingredients count: \(ingredients.count), indices to delete: \(indices)")
                // Create a new array with the items removed
                var newIngredients = ingredients
                newIngredients.remove(atOffsets: indices)
                print("DEBUG: After deletion - ingredients count: \(newIngredients.count)")
                
                // Ensure we always have at least one ingredient
                if newIngredients.isEmpty {
                    print("DEBUG: Ingredients empty, adding placeholder")
                    newIngredients = [""]
                }
                
                // Update the binding
                ingredients = newIngredients
            }
            
            Button("Add Ingredient") {
                print("DEBUG: Before adding - ingredients count: \(ingredients.count)")
                // Create a new array with the added item
                var newIngredients = ingredients
                newIngredients.append("")
                print("DEBUG: After adding - ingredients count: \(newIngredients.count)")
                
                // Update the binding
                ingredients = newIngredients
            }
        }
    }
}

private struct PhotoSection: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @ObservedObject var imageViewModel: AddFoodEntryView.ImageViewModel
    
    var body: some View {
        Section("Photo") {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let image = imageViewModel.selectedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                }
            }
        }
        .onChange(of: selectedPhoto) { newValue in
            if let item = newValue {
                imageViewModel.loadImage(from: item)
            }
        }
    }
}

private struct ProgressSection: View {
    let progress: Double
    
    var body: some View {
        Section {
            ProgressView(value: progress) {
                Text("Uploading...")
            }
        }
    }
}

extension AddFoodEntryView {
    @MainActor class ImageViewModel: ObservableObject {
        @Published var selectedImage: Image?
        
        func loadImage(from item: PhotosPickerItem) {
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                selectedImage = Image(uiImage: uiImage)
            }
        }
    }
} 
