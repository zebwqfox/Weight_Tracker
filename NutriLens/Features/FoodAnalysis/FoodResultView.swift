import SwiftUI
import SwiftData

struct FoodResultView: View {
    let nutrition: NutritionInfo
    let image: UIImage?
    let mealType: String
    let onSave: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food image thumbnail
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }

                    // Calorie summary card
                    calorieSummaryCard

                    // Dishes list
                    dishesCard

                    // Macro breakdown
                    macroCard

                    // Health score & suggestion
                    healthCard

                    // Save button
                    if !saved {
                        saveButton
                    } else {
                        savedConfirmation
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("分析结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var calorieSummaryCard: some View {
        VStack(spacing: 8) {
            Text("总热量")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(Int(nutrition.totalCalories))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)

            Text("千卡 (kcal)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.orange.opacity(0.2), lineWidth: 1.5)
        )
        .padding(.horizontal)
    }

    private var dishesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("识别菜品", systemImage: "list.bullet.rectangle")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(nutrition.dishes) { dish in
                    HStack {
                        Text(dish.emoji)
                            .font(.title2)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(dish.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(dish.portion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(dish.calories)) kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    if dish.id != nutrition.dishes.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private var macroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("营养素", systemImage: "chart.pie.fill")
                .font(.headline)

            HStack(spacing: 12) {
                MacroCell(label: "蛋白质", value: nutrition.protein, unit: "g", color: .blue)
                MacroCell(label: "碳水", value: nutrition.carbohydrates, unit: "g", color: .orange)
                MacroCell(label: "脂肪", value: nutrition.fat, unit: "g", color: .yellow)
                MacroCell(label: "膳食纤维", value: nutrition.fiber, unit: "g", color: .green)
            }
        }
        .padding(.horizontal)
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("健康评估", systemImage: "heart.fill")
                .font(.headline)

            HStack(alignment: .top, spacing: 16) {
                // Health score circle
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 6)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: CGFloat(nutrition.healthScore) / 10.0)
                        .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(nutrition.healthScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ 10")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(healthScoreLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(healthScoreColor)

                    Text(nutrition.suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }

    private var healthScoreColor: Color {
        switch nutrition.healthScore {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }

    private var healthScoreLabel: String {
        switch nutrition.healthScore {
        case 9...10: return "非常健康"
        case 7...8: return "比较健康"
        case 5...6: return "一般"
        default: return "需要改善"
        }
    }

    private var saveButton: some View {
        Button {
            saveEntry()
        } label: {
            Label("保存到日志", systemImage: "square.and.arrow.down")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
    }

    private var savedConfirmation: some View {
        Label("已保存到日志", systemImage: "checkmark.circle.fill")
            .font(.headline)
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
    }

    private func saveEntry() {
        let entry = FoodEntry(
            mealType: mealType,
            imageData: image?.jpegData(compressionQuality: 0.6),
            totalCalories: nutrition.totalCalories,
            dishes: nutrition.dishes.map { "\($0.emoji) \($0.name)" },
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates,
            fat: nutrition.fat,
            healthScore: nutrition.healthScore,
            suggestion: nutrition.suggestion
        )
        modelContext.insert(entry)
        withAnimation {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
            onSave()
        }
    }
}

// MARK: - Macro Cell

struct MacroCell: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(Int(value))\(unit)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
