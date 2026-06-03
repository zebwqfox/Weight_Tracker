import SwiftUI
import SwiftData

struct DailyFoodLogView: View {
    @Query(sort: \FoodEntry.date, order: .reverse) var allEntries: [FoodEntry]
    @Environment(\.modelContext) var modelContext

    @State private var selectedDate = Date.now
    @AppStorage("calorie_goal") private var calorieGoal: Double = 2000

    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCaloriesToday: Double {
        todayEntries.reduce(0) { $0 + $1.totalCalories }
    }

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(totalCaloriesToday / calorieGoal, 1.0)
    }

    private var remaining: Int {
        max(0, Int(calorieGoal - totalCaloriesToday))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.sectionSpacing) {
                    dateSelector
                    heroCard
                    if todayEntries.isEmpty {
                        emptyState
                    } else {
                        mealEntriesSection
                    }
                }
                .padding(.horizontal, DS.spacing)
                .padding(.bottom, 30)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("今日饮食")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        HStack {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.brand)
                    .frame(width: 38, height: 38)
                    .background(Color.card, in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate.formatted(.dateTime.month(.wide).day()))
                    .font(.headline)
                Text(Calendar.current.isDateInToday(selectedDate)
                     ? "今天"
                     : selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if !Calendar.current.isDateInToday(selectedDate) { shift(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Calendar.current.isDateInToday(selectedDate) ? Color.gray.opacity(0.4) : Color.brand)
                    .frame(width: 38, height: 38)
                    .background(Color.card, in: Circle())
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
    }

    private func shift(by days: Int) {
        withAnimation(.snappy) {
            selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 24) {
                calorieRing
                VStack(alignment: .leading, spacing: 12) {
                    statLine(label: "目标", value: Int(calorieGoal), color: .white.opacity(0.85))
                    statLine(label: "已摄入", value: Int(totalCaloriesToday), color: .white)
                    statLine(label: "剩余", value: remaining, color: .white.opacity(0.95))
                }
                Spacer(minLength: 0)
            }
        }
        .padding(24)
        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .shadow(color: Color.brand.opacity(0.35), radius: 18, y: 8)
    }

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 11)

            Circle()
                .trim(from: 0, to: calorieProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: calorieProgress)

            VStack(spacing: 1) {
                Text("\(Int(totalCaloriesToday))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("kcal")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 112, height: 112)
    }

    private func statLine(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 44, alignment: .leading)
            Text("\(value)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Meal Entries

    private var mealEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "今日餐食", systemImage: "fork.knife")
                .padding(.horizontal, 4)

            ForEach(todayEntries) { entry in
                FoodEntryCard(entry: entry)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { modelContext.delete(entry) }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "fork.knife")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.brand)
            }
            Text("今天还没有记录")
                .font(.title3.weight(.semibold))
            Text("切换到「拍照分析」，拍下你的餐食")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .card()
    }
}

// MARK: - Food Entry Card

struct FoodEntryCard: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    PillTag(text: entry.mealType)
                    Spacer()
                    Text(entry.date.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(entry.dishes.prefix(3).joined(separator: " · "))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.calorie)
                    Text("\(Int(entry.totalCalories)) kcal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.calorie)
                }
            }
        }
        .card(padding: 12)
    }

    private var thumbnail: some View {
        Group {
            if let data = entry.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient.soft(.brand).opacity(0.18)
                    Image(systemName: "fork.knife")
                        .font(.title3)
                        .foregroundStyle(.brand)
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    DailyFoodLogView()
        .modelContainer(for: [FoodEntry.self], inMemory: true)
}
