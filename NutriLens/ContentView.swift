import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("食物日志", systemImage: "fork.knife") {
                DailyFoodLogView()
            }
            Tab("拍照分析", systemImage: "camera.fill") {
                FoodAnalysisView()
            }
            Tab("扫码", systemImage: "qrcode.viewfinder") {
                QRScannerView()
            }
            Tab("减重工具", systemImage: "chart.line.uptrend.xyaxis") {
                WeightToolsView()
            }
        }
        .tabViewStyle(.automatic)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self], inMemory: true)
}
