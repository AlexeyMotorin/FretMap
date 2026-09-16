import SwiftUI

struct MasteryDailyStatistics: View {
    @State private var selectedDate = Date()
    @State private var showingAll = false
    @ObservedObject var store: MasteryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let calendar = Calendar.current
            let practiceDays = Set(store.exercises.flatMap { exercise in
                exercise.results.map(\.date) + exercise.sessions.filter { $0.seconds > 0 }.map(\.date)
            }.filter { $0 <= context.date }.map { calendar.startOfDay(for: $0) })
            let exercises = store.exercises.filter { exercise in
                exercise.results.contains { calendar.isDate($0.date, inSameDayAs: selectedDate) } ||
                exercise.sessions.contains { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            }
            let results = exercises.flatMap(\.results).filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            let seconds = exercises.flatMap(\.sessions)
                .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
                .reduce(0) { $0 + $1.seconds }
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        MasteryCalendar(selectedDate: $selectedDate, practiceDays: practiceDays, today: context.date)
                        Text("mastery.day.legend").font(.caption).foregroundStyle(.secondary)
                        Button("mastery.statistics.show.all") { showingAll = true }
                            .buttonStyle(.bordered)
                    }
                    .padding(16).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedDate, style: .date).font(.headline)
                        row("mastery.daily.exercises", value: String(exercises.count))
                        row("mastery.daily.results", value: String(results.count))
                        row("mastery.daily.clean", value: String(results.filter(\.clean).count))
                        row("mastery.practice.total", value: Duration.seconds(seconds).formatted(.time(pattern: .hourMinuteSecond)))
                        Text("mastery.daily.time.hint").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("mastery.daily.results").font(.headline)
                        if exercises.isEmpty { Text("mastery.daily.empty").foregroundStyle(.secondary) }
                        ForEach(exercises) { exercise in
                            let dayResults = exercise.results.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(exercise.name).font(.headline)
                                row("mastery.daily.results", value: String(dayResults.count))
                                row("mastery.best", value: dayResults.filter(\.clean).map(\.bpm).max().map { "\($0) BPM" } ?? "—")
                                ForEach(dayResults.sorted { $0.date > $1.date }) { result in
                                    HStack {
                                        Text(result.date, style: .time)
                                        Spacer()
                                        Text("\(result.bpm) BPM").monospacedDigit()
                                    }.font(.subheadline)
                                    MasteryResultDetails(result: result)
                                }
                            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                    .padding(16)
                }
                .background(AppBackgroundView())
                .sheet(isPresented: $showingAll) { MasteryAllStatistics(store: store) }
                .navigationTitle("mastery.daily.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("mastery.done") { dismiss() } } }
            }
        }
    }

    private func row(_ title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(.secondary)
        }
    }
}
