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
                VStack(spacing: DS.sectionSpacing) {
                    heroCalorie
                    dishesCard
                    macroCard
                    healthCard
                    if saved { savedConfirmation } else { saveButton }
                }
                .padding(.horizontal, DS.spacing)
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("分析结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.brand)
                }
            }
        }
    }

    // MARK: - Hero Calorie (with image backdrop)

    private var heroCalorie: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.1), .black.opacity(0.65)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            } else {
                LinearGradient.calorie.frame(height: 220)
            }

            VStack(spacing: 4) {
                Text("总热量")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text("\(Int(nutrition.totalCalories))")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("千卡 · \(mealType)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
    }

    // MARK: - Dishes

    private var dishesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "识别菜品", systemImage: "list.bullet.rectangle.fill")

            VStack(spacing: 0) {
                ForEach(Array(nutrition.dishes.enumerated()), id: \.element.id) { index, dish in
                    HStack(spacing: 12) {
                        Text(dish.emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(dish.name)
                                .font(.subheadline.weight(.medium))
                            Text(dish.portion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(dish.calories))")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.calorie)
                        + Text(" kcal")
                            .font(.caption2)
                            .foregroundStyle(.calorie.opacity(0.7))
                    }
                    .padding(.vertical, 10)

                    if index < nutrition.dishes.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Macros

    private var macroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "营养构成", systemImage: "chart.pie.fill")

            HStack(spacing: 10) {
                MacroCell(label: "蛋白质", value: nutrition.protein, unit: "g", color: .protein)
                MacroCell(label: "碳水", value: nutrition.carbohydrates, unit: "g", color: .carb)
                MacroCell(label: "脂肪", value: nutrition.fat, unit: "g", color: .fat)
                MacroCell(label: "纤维", value: nutrition.fiber, unit: "g", color: .fiber)
            }
        }
        .card()
    }

    // MARK: - Health

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "健康评估", systemImage: "heart.fill", tint: healthColor)

            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle().stroke(healthColor.opacity(0.15), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: CGFloat(nutrition.healthScore) / 10.0)
                        .stroke(healthColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(nutrition.healthScore)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(healthColor)
                        Text("/10")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 6) {
                    Text(healthLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(healthColor)
                    Text(nutrition.suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .card()
    }

    private var healthColor: Color {
        switch nutrition.healthScore {
        case 8...10: return .brand
        case 5...7: return .calorie
        default: return .calorieDeep
        }
    }

    private var healthLabel: String {
        switch nutrition.healthScore {
        case 9...10: return "非常健康"
        case 7...8: return "比较健康"
        case 5...6: return "中规中矩"
        default: return "需要改善"
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveEntry()
        } label: {
            Label("保存到今日日志", systemImage: "square.and.arrow.down.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))
                .shadow(color: Color.brand.opacity(0.3), radius: 10, y: 4)
        }
    }

    private var savedConfirmation: some View {
        Label("已保存到日志", systemImage: "checkmark.circle.fill")
            .font(.headline)
            .foregroundStyle(.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))
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
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
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
            Text("\(Int(value))")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            + Text(unit)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: DS.pillRadius, style: .continuous))
    }
}
