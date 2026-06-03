import SwiftUI
import PhotosUI

@Observable
@MainActor
class FoodAnalysisViewModel {
    var selectedPhotoItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var nutritionInfo: NutritionInfo?
    var isAnalyzing = false
    var showResult = false
    var error: String?
    var showError = false
    var mealType = "午餐"
    var showCamera = false

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selectedImage = image
    }

    func analyze() async {
        guard let image = selectedImage else { return }
        isAnalyzing = true
        error = nil
        do {
            let result = try await AIAnalysisService.shared.analyzeFood(image: image)
            nutritionInfo = result
            isAnalyzing = false
            showResult = true
        } catch {
            self.error = error.localizedDescription
            showError = true
            isAnalyzing = false
        }
    }

    func reset() {
        selectedPhotoItem = nil
        selectedImage = nil
        nutritionInfo = nil
        showResult = false
        error = nil
    }
}
