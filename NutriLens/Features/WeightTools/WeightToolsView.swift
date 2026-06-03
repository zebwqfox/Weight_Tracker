import SwiftUI
import SwiftData
import Charts

struct WeightToolsView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) var weightEntries: [WeightEntry]
    @Environment(\.modelContext) var modelContext

    @AppStorage("calorie_goal") var calorieGoal: Double = 2000
    @AppStorage("height_cm") var heightCM: Double = 170
    @AppStorage("target_weight") var targetWeight: Double = 65
    @State private var showWeightEntry = false
    @State private var showSettings = false

    private var latestWeight: Double? {
        weightEntries.first?.weight
    }

    private var bmi: Double? {
        guard let w = latestWeight, heightCM > 0 else { return nil }
        let hMeters = heightCM / 100
        return w / (hMeters * hMeters)
    }

    private var bmiCategory: (String, Color) {
        guard let bmi else { return ("未知", .gray) }
        switch bmi {
        case ..<18.5: return ("偏轻", .blue)
        case 18.5..<24: return ("正常", .green)
        case 24..<28: return ("超重", .orange)
        default: return ("肥胖", .red)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // BMI card
                    bmiCard

                    // Weight chart
                    weightChartCard

                    // Goals card
                    goalsCard

                    // Calorie calculator
                    calorieCalculatorCard
                }
                .padding()
            }
            .navigationTitle("减重工具")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWeightEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showWeightEntry) {
                WeightEntrySheet()
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSettings) {
                HealthSettingsView(
                    heightCM: $heightCM,
                    targetWeight: $targetWeight,
                    calorieGoal: $calorieGoal
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Cards

    private var bmiCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("BMI 指数")
                    .font(.headline)
                Spacer()
                if let bmi {
                    Text(String(format: "%.1f", bmi))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(bmiCategory.1)
                    Text(bmiCategory.0)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(bmiCategory.1)
                }
            }

            // BMI scale bar
            BMIScaleView(bmi: bmi)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前体重")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(latestWeight.map { "\($0, specifier: "%.1f") kg" } ?? "未记录")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("目标体重")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(targetWeight, specifier: "%.1f") kg")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }

            if let current = latestWeight {
                let diff = current - targetWeight
                if diff > 0 {
                    Label("距目标还需减 \(diff, specifier: "%.1f") kg", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if diff < 0 {
                    Label("已超额完成目标！保持下去", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("达到目标体重！", systemImage: "star.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("体重趋势", systemImage: "chart.line.downtrend.xyaxis")
                .font(.headline)

            if weightEntries.count >= 2 {
                Chart {
                    ForEach(weightEntries.prefix(14).reversed()) { entry in
                        LineMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(.tint)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(.tint)

                        AreaMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(.tint.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }

                    RuleMark(y: .value("目标", targetWeight))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .foregroundStyle(.orange)
                        .annotation(position: .trailing) {
                            Text("目标")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 160)
            } else {
                Text("记录至少 2 天的体重数据后\n将显示趋势图")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            }

            Button {
                showWeightEntry = true
            } label: {
                Label("记录今日体重", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("每日目标", systemImage: "target")
                .font(.headline)

            HStack(spacing: 16) {
                GoalCell(
                    icon: "flame.fill",
                    color: .orange,
                    value: "\(Int(calorieGoal))",
                    unit: "kcal",
                    label: "热量目标"
                )
                GoalCell(
                    icon: "drop.fill",
                    color: .blue,
                    value: "2000",
                    unit: "ml",
                    label: "饮水目标"
                )
                GoalCell(
                    icon: "figure.walk",
                    color: .green,
                    value: "8000",
                    unit: "步",
                    label: "步数目标"
                )
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var calorieCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("推荐热量计算", systemImage: "function")
                .font(.headline)

            if let weight = latestWeight {
                let bmr = 10 * weight + 6.25 * heightCM - 5 * 30 + 5
                let deficit = bmr * 1.2 - 500

                VStack(spacing: 10) {
                    FormulaRow(label: "基础代谢率 (BMR)", value: "\(Int(bmr)) kcal")
                    FormulaRow(label: "久坐维持热量 (×1.2)", value: "\(Int(bmr * 1.2)) kcal")
                    Divider()
                    FormulaRow(label: "减重建议热量 (−500)", value: "\(Int(deficit)) kcal", highlighted: true)
                }
                .padding(14)
                .background(.tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                Text("* 基于 Mifflin-St Jeor 公式，假设年龄 30 岁男性")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("请先记录一次体重")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Weight Entry Sheet

struct WeightEntrySheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var weight: Double = 70
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("今日体重") {
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("备注（可选）") {
                    TextField("添加备注", text: $note)
                }
            }
            .navigationTitle("记录体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let entry = WeightEntry(weight: weight, note: note)
                        modelContext.insert(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Health Settings

struct HealthSettingsView: View {
    @Binding var heightCM: Double
    @Binding var targetWeight: Double
    @Binding var calorieGoal: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("身体数据") {
                    HStack {
                        Text("身高")
                        Spacer()
                        TextField("cm", value: $heightCM, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("目标体重")
                        Spacer()
                        TextField("kg", value: $targetWeight, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("每日目标") {
                    HStack {
                        Text("热量目标")
                        Spacer()
                        TextField("kcal", value: $calorieGoal, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("健康设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BMIScaleView: View {
    let bmi: Double?

    private let segments: [(String, Color, ClosedRange<Double>)] = [
        ("偏轻", .blue, 10...18.5),
        ("正常", .green, 18.5...24),
        ("超重", .orange, 24...28),
        ("肥胖", .red, 28...40)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(segments, id: \.0) { segment in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segment.1.opacity(0.25))
                            .frame(width: segmentWidth(segment.2, total: geo.size.width))
                    }
                }

                if let bmi {
                    let xPos = bmiPosition(bmi, total: geo.size.width)
                    Capsule()
                        .fill(.white)
                        .shadow(radius: 4)
                        .frame(width: 4, height: 24)
                        .offset(x: xPos - 2)
                        .animation(.spring, value: bmi)
                }
            }
        }
        .frame(height: 20)
    }

    private func segmentWidth(_ range: ClosedRange<Double>, total: CGFloat) -> CGFloat {
        let totalRange = 40.0 - 10.0
        return CGFloat((range.upperBound - range.lowerBound) / totalRange) * total
    }

    private func bmiPosition(_ bmi: Double, total: CGFloat) -> CGFloat {
        let clamped = min(max(bmi, 10), 40)
        return CGFloat((clamped - 10) / 30) * total
    }
}

struct GoalCell: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FormulaRow: View {
    let label: String
    let value: String
    var highlighted: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(highlighted ? .primary : .secondary)
                .fontWeight(highlighted ? .semibold : .regular)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(highlighted ? .tint : .primary)
        }
    }
}

#Preview {
    WeightToolsView()
        .modelContainer(for: [WeightEntry.self], inMemory: true)
}
