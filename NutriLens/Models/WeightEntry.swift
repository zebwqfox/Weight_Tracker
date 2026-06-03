import Foundation
import SwiftData

@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var weight: Double
    var note: String

    init(date: Date = .now, weight: Double, note: String = "") {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.note = note
    }
}
