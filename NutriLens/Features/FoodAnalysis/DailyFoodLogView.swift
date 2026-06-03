import SwiftUI
import SwiftData

struct DailyFoodLogView: View {
    @Query(sort: \FoodEntry.date, order: .reverse) var allEntries: [FoodEntry]
    @Environment(\.modelContext) var modelContext

    @State private var selectedDate = Date.now
    @State private var calorieGoal: Double = UserDefaults.standard.double(forKey: "calorie_goal") == 0
        ? 2000
        : UserDefaults.standard.double(forKey: "calorie_goal")

    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCaloriesToday: Double {
        todayEntries.reduce(0) { $0 + $1.totalCalories }
    }

    private var calorieProgress: Double {
        min(totalCaloriesToday / calorieGoal, 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date selector
                    dateSelectorCard

                    // Calorie ring summary
                    calorieSummarySection

                    // Meal entries
                    if todayEntries.isEmpty {
                        emptyState
                    } else {
                        mealEntriesSection
                    }
                }
                .padding()
            }
            .navigationTitle("今日饮食")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var dateSelectorCard: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate.formatted(.dateTime.month(.wide).day()))
                    .font(.headline)
                Text(Calendar.current.isDateInToday(selectedDate) ? "今天" : selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if !Calendar.current.isDateInToday(selectedDate) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
    }

    private var calorieSummarySection: some View {
        HStack(spacing: 20) {
            // Calorie ring
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 10)

                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(
                        calorieProgress > 0.9 ? Color.red : Color.orange,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: calorieProgress)

                VStack(spacing: 2) {
                    Text("\(Int(totalCaloriesToday))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 10) {
                StatRow(label: "目标", value: "\(Int(calorieGoal)) kcal", color: .blue)
                StatRow(label: "已摄入", value: "\(Int(totalCaloriesToday)) kcal", color: .orange)
                StatRow(
                    label: "剩余",
                    value: "\(max(0, Int(calorieGoal - totalCaloriesToday))) kcal",
                    color: totalCaloriesToday > calorieGoal ? .red : .green
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var mealEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日餐食")
                .font(.headline)

            ForEach(todayEntries) { entry in
                FoodEntryCard(entry: entry)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundStyle(.quaternary)

            Text("今天还没有记录")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("点击「拍照分析」拍下你的餐食")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

struct FoodEntryCard: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 14) {
            if let data = entry.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mealType)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)

                    Spacer()

                    Text(entry.date.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(entry.dishes.prefix(3).joined(separator: "  "))
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(Int(entry.totalCalories)) kcal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    DailyFoodLogView()
        .modelContainer(for: [FoodEntry.self], inMemory: true)
}
