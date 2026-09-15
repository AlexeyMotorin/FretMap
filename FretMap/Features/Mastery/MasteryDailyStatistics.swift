import SwiftUI

struct MasteryDailyStatistics: View {
    @State private var selectedDate = Date()
    @ObservedObject var store: MasteryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let calendar = Calendar.current
            let exercises = store.exercises.filter { exercise in
                exercise.results.contains { calendar.isDate($0.date, inSameDayAs: selectedDate) } ||
                exercise.sessions.contains { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            }
            let results = exercises.flatMap(\.results).filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            let seconds = exercises.flatMap(\.sessions)
                .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
                .reduce(0) { $0 + $1.seconds }
            NavigationStack {
                List {
                    Section {
                        DatePicker("mastery.daily.date", selection: $selectedDate,
                                   in: ...context.date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    Section {
                        Text(selectedDate, style: .date).font(.headline)
                        row("mastery.daily.exercises", value: String(exercises.count))
                        row("mastery.daily.results", value: String(results.count))
                        row("mastery.daily.clean", value: String(results.filter(\.clean).count))
                        row("mastery.practice.total", value: Duration.seconds(seconds).formatted(.time(pattern: .hourMinuteSecond)))
                        Text("mastery.daily.time.hint").font(.caption).foregroundStyle(.secondary)
                    }
                    Section("mastery.daily.results") {
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
                            }.padding(.vertical, 4)
                        }
                    }
                }
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
