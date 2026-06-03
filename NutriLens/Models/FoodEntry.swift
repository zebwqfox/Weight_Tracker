import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var date: Date
    var mealType: String
    var imageData: Data?
    var totalCalories: Double
    var dishes: [String]
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var healthScore: Int
    var suggestion: String

    init(
        date: Date = .now,
        mealType: String = "午餐",
        imageData: Data? = nil,
        totalCalories: Double,
        dishes: [String],
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        healthScore: Int = 0,
        suggestion: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.mealType = mealType
        self.imageData = imageData
        self.totalCalories = totalCalories
        self.dishes = dishes
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.healthScore = healthScore
        self.suggestion = suggestion
    }

    static let mealTypes = ["早餐", "早茶", "午餐", "下午茶", "晚餐", "夜宵", "零食"]
}
