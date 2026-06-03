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

    private var latestWeight: Double? { weightEntries.first?.weight }

    private var bmi: Double? {
        guard let w = latestWeight, heightCM > 0 else { return nil }
        let h = heightCM / 100
        return w / (h * h)
    }

    private var bmiCategory: (String, Color) {
        guard let bmi else { return ("未知", .gray) }
        switch bmi {
        case ..<18.5: return ("偏轻", .protein)
        case 18.5..<24: return ("正常", .brand)
        case 24..<28: return ("超重", .calorie)
        default: return ("肥胖", .calorieDeep)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.sectionSpacing) {
                    bmiCard
                    weightChartCard
                    goalsCard
                    calorieCalculatorCard
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, DS.spacing)
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("减重工具")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3").foregroundStyle(.brand)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWeightEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.brand)
                    }
                }
            }
            .sheet(isPresented: $showWeightEntry) {
                WeightEntrySheet()
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSettings) {
                HealthSettingsView(heightCM: $heightCM, targetWeight: $targetWeight, calorieGoal: $calorieGoal)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - BMI Card

    private var bmiCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "BMI 指数", systemImage: "figure.stand", tint: bmiCategory.1)
                if let bmi {
                    Text(String(format: "%.1f", bmi))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(bmiCategory.1)
                    PillTag(text: bmiCategory.0, color: bmiCategory.1)
                }
            }

            BMIScaleView(bmi: bmi)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("当前体重").font(.caption).foregroundStyle(.secondary)
                    Text(latestWeight.map { String(format: "%.1f kg", $0) } ?? "未记录")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("目标体重").font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%.1f kg", targetWeight))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.brand)
                }
            }

            if let current = latestWeight {
                let diff = current - targetWeight
                Group {
                    if diff > 0.05 {
                        Label("距目标还需减 \(String(format: "%.1f", diff)) kg", systemImage: "arrow.down.circle.fill")
                            .foregroundStyle(.calorie)
                    } else if diff < -0.05 {
                        Label("已超额完成目标，保持下去！", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.brand)
                    } else {
                        Label("已达到目标体重 🎉", systemImage: "star.circle.fill")
                            .foregroundStyle(.fat)
                    }
                }
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    // MARK: - Weight Chart

    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "体重趋势", systemImage: "chart.line.downtrend.xyaxis")

            if weightEntries.count >= 2 {
                Chart {
                    ForEach(weightEntries.prefix(14).reversed()) { entry in
                        AreaMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [Color.brand.opacity(0.25), Color.brand.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(Color.brand)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("体重", entry.weight)
                        )
                        .foregroundStyle(Color.brand)
                        .symbolSize(40)
                    }

                    RuleMark(y: .value("目标", targetWeight))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .foregroundStyle(Color.calorie)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("目标").font(.caption2).foregroundStyle(.calorie)
                        }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 170)
            } else {
                emptyChartHint
            }

            Button {
                showWeightEntry = true
            } label: {
                Label("记录今日体重", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.pillRadius, style: .continuous))
            }
        }
        .card()
    }

    private var emptyChartHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("记录至少 2 天体重\n即可查看趋势图")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Goals

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "每日目标", systemImage: "target")
            HStack(spacing: 10) {
                GoalCell(icon: "flame.fill", color: .calorie, value: "\(Int(calorieGoal))", unit: "kcal", label: "热量")
                GoalCell(icon: "drop.fill", color: .protein, value: "2000", unit: "ml", label: "饮水")
                GoalCell(icon: "figure.walk", color: .brand, value: "8000", unit: "步", label: "步数")
            }
        }
        .card()
    }

    // MARK: - Calorie Calculator

    private var calorieCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "推荐热量", systemImage: "function")

            if let weight = latestWeight {
                let bmr = 10 * weight + 6.25 * heightCM - 5 * 30 + 5
                let maintain = bmr * 1.2
                let deficit = maintain - 500

                VStack(spacing: 10) {
                    FormulaRow(label: "基础代谢 (BMR)", value: "\(Int(bmr)) kcal")
                    FormulaRow(label: "久坐维持 (×1.2)", value: "\(Int(maintain)) kcal")
                    Divider()
                    FormulaRow(label: "减重建议 (−500)", value: "\(Int(deficit)) kcal", highlighted: true)
                }
                .padding(14)
                .background(Color.brand.opacity(0.06), in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))

                Text("* 基于 Mifflin-St Jeor 公式，假设 30 岁男性")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("请先记录一次体重")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .card()
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
                        Text("kg").foregroundStyle(.secondary)
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
                        modelContext.insert(WeightEntry(weight: weight, note: note))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.brand)
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
                    labeledField("身高", value: $heightCM, unit: "cm")
                    labeledField("目标体重", value: $targetWeight, unit: "kg")
                }
                Section("每日目标") {
                    labeledField("热量目标", value: $calorieGoal, unit: "kcal")
                }
            }
            .navigationTitle("健康设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.fontWeight(.semibold).tint(.brand)
                }
            }
        }
    }

    private func labeledField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(unit, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}

// MARK: - BMI Scale

struct BMIScaleView: View {
    let bmi: Double?

    private let segments: [(String, Color, ClosedRange<Double>)] = [
        ("偏轻", .protein, 10...18.5),
        ("正常", .brand, 18.5...24),
        ("超重", .calorie, 24...28),
        ("肥胖", .calorieDeep, 28...40)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 3) {
                    ForEach(segments, id: \.0) { segment in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segment.1.opacity(0.3))
                            .frame(width: segmentWidth(segment.2, total: geo.size.width))
                    }
                }
                if let bmi {
                    Capsule()
                        .fill(.white)
                        .frame(width: 5, height: 26)
                        .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 3)
                        .offset(x: position(bmi, total: geo.size.width) - 2.5)
                        .animation(.spring, value: bmi)
                }
            }
        }
        .frame(height: 22)
    }

    private func segmentWidth(_ range: ClosedRange<Double>, total: CGFloat) -> CGFloat {
        CGFloat((range.upperBound - range.lowerBound) / 30.0) * (total - 9)
    }

    private func position(_ bmi: Double, total: CGFloat) -> CGFloat {
        let clamped = min(max(bmi, 10), 40)
        return CGFloat((clamped - 10) / 30) * total
    }
}

// MARK: - Goal Cell

struct GoalCell: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 7) {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: DS.pillRadius, style: .continuous))
    }
}

// MARK: - Formula Row

struct FormulaRow: View {
    let label: String
    let value: String
    var highlighted: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(highlighted ? Color.primary : Color.secondary)
                .fontWeight(highlighted ? .semibold : .regular)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(highlighted ? Color.brand : Color.primary)
        }
    }
}

#Preview {
    WeightToolsView()
        .modelContainer(for: [WeightEntry.self], inMemory: true)
}
