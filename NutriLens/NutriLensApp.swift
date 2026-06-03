import SwiftUI
import SwiftData

@main
struct NutriLensApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FoodEntry.self, WeightEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
