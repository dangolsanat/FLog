import SwiftUI
import PhotosUI

struct EditFoodEntryView: View {
    let entry: FoodEntry
    let onSave: (FoodEntry) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var description: String
    @State private var selectedMealType: FoodEntry.MealType
    @State private var ingredients: [String]
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedDate: Date
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var isLoading = false
    @State private var error: String?
    
    init(entry: FoodEntry, onSave: @escaping (FoodEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        
        // Initialize all state properties here
        _title = State(initialValue: entry.title)
        _description = State(initialValue: entry.description ?? "")
        _selectedMealType = State(initialValue: entry.mealType)
        _ingredients = State(initialValue: entry.ingredients.isEmpty ? [""] : entry.ingredients)
        _selectedDate = State(initialValue: entry.mealDate)
    }
    
    var body: some View {
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
                        AsyncImage(url: URL(string: entry.photoURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } placeholder: {
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
            }
        }
        .navigationTitle("Edit Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    isLoading = true
                    let updatedEntry = FoodEntry(
                        id: entry.id,
                        deviceId: entry.deviceId,
                        title: title,
                        description: description.isEmpty ? nil : description,
                        photoURL: entry.photoURL,
                        mealType: selectedMealType,
                        ingredients: ingredients.filter { !$0.isEmpty },
                        dateCreated: entry.dateCreated,
                        mealDate: selectedDate
                    )
                    onSave(updatedEntry)
                    dismiss()
                }
                .disabled(title.isEmpty || isLoading)
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: {
            Text(error ?? "Unknown error")
        })
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