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
    @State private var error: String?
    @StateObject private var imageViewModel = ImageViewModel()
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section("Ingredients") {
                    ForEach($ingredients.indices, id: \.self) { index in
                        TextField("Ingredient \(index + 1)", text: $ingredients[index])
                    }
                    .onDelete { indices in
                        ingredients.remove(atOffsets: indices)
                    }
                    
                    Button("Add Ingredient") {
                        ingredients.append("")
                    }
                }
                
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
                
                if let progress = foodEntryService.uploadProgress {
                    Section {
                        ProgressView(value: progress) {
                            Text("Uploading...")
                        }
                    }
                }
            }
            .navigationTitle("Add Food Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            do {
                                try await foodEntryService.addEntry(
                                    title: title,
                                    description: description,
                                    mealType: selectedMealType,
                                    ingredients: ingredients,
                                    photo: selectedPhoto,
                                    mealDate: selectedDate
                                )
                                // Reset form
                                title = ""
                                description = ""
                                selectedMealType = .breakfast
                                ingredients = [""]
                                selectedPhoto = nil
                                selectedDate = Date()
                                imageViewModel.selectedImage = nil
                                
                                // Switch to home tab
                                tabSelection.wrappedValue = 0
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                    .disabled(title.isEmpty || foodEntryService.isLoading)
                }
            }
            .alert("Error", isPresented: .constant(error != nil), actions: {
                Button("OK") { error = nil }
            }, message: {
                Text(error ?? "Unknown error")
            })
        }
        .onChange(of: selectedPhoto) { newValue in
            if let item = newValue {
                imageViewModel.loadImage(from: item)
            }
        }
    }
    
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