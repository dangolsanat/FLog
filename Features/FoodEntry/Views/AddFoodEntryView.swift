import SwiftUI
import PhotosUI

struct AddFoodEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var foodEntryService: FoodEntryService
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedMealType = MealType.breakfast
    @State private var ingredients: [String] = [""]
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isLoading = false
    @State private var error: String?
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var selectedDate = Date()
    @Environment(\.tabSelection) private var tabSelection
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
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
                            Label("Select Photo", systemImage: "photo")
                        }
                    }
                    
                    if let progress = foodEntryService.uploadProgress {
                        ProgressView(value: progress) {
                            Text("Uploading... \(Int(progress * 100))%")
                        }
                    }
                }
            }
            .navigationTitle("Add Food Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
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
        }
        .onChange(of: selectedPhoto) { newValue in
            if let item = newValue {
                imageViewModel.loadImage(from: item)
            }
        }
    }
    
    private func saveEntry() {
        isLoading = true
        error = nil
        
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
                await MainActor.run {
                    isLoading = false
                    resetForm()
                    tabSelection.wrappedValue = 0 // Switch to home tab
                }
            } catch {
                self.error = error.localizedDescription
                print("Upload error: \(error)")
            }
            isLoading = false
        }
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedMealType = .breakfast
        ingredients = [""]
        selectedPhoto = nil
        selectedDate = Date()
        imageViewModel.selectedImage = nil
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