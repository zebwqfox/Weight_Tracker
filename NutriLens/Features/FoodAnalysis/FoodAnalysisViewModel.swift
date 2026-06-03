import SwiftUI
import PhotosUI

@Observable
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
        await MainActor.run {
            self.selectedImage = image
        }
    }

    func analyze() async {
        guard let image = selectedImage else { return }
        await MainActor.run {
            isAnalyzing = true
            error = nil
        }
        do {
            let result = try await AIAnalysisService.shared.analyzeFood(image: image)
            await MainActor.run {
                self.nutritionInfo = result
                self.isAnalyzing = false
                self.showResult = true
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.showError = true
                self.isAnalyzing = false
            }
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
