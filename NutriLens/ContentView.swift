import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("今日", systemImage: "sun.max.fill") {
                DailyFoodLogView()
            }
            Tab("拍照分析", systemImage: "camera.fill") {
                FoodAnalysisView()
            }
            Tab("扫码", systemImage: "qrcode.viewfinder") {
                QRScannerView()
            }
            Tab("减重", systemImage: "chart.line.uptrend.xyaxis") {
                WeightToolsView()
            }
        }
        .tint(.brand)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self], inMemory: true)
}
