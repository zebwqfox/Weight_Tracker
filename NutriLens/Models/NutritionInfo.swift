import Foundation

struct NutritionInfo: Codable, Equatable {
    var totalCalories: Double
    var dishes: [DishItem]
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double
    var healthScore: Int
    var suggestion: String

    struct DishItem: Codable, Identifiable, Equatable {
        var id = UUID()
        var name: String
        var calories: Double
        var portion: String
        var emoji: String

        enum CodingKeys: String, CodingKey {
            case name, calories, portion, emoji
        }
    }

    static let empty = NutritionInfo(
        totalCalories: 0,
        dishes: [],
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        healthScore: 0,
        suggestion: ""
    )
}
