import SwiftUI

struct MasteryAllStatistics: View {
    @ObservedObject var store: MasteryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let exercises = store.exercises
        let results = exercises.flatMap(\.results)
        let sessions = exercises.flatMap(\.sessions)
        let days = Set((results.map(\.date) + sessions.filter { $0.seconds > 0 }.map(\.date))
            .filter { $0 <= Date() }.map { Calendar.current.startOfDay(for: $0) })
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("mastery.statistics.all").font(.headline)
                        row("mastery.training.days", value: String(days.count))
                        row("mastery.statistics.exercises", value: String(exercises.count))
                        row("mastery.active", value: String(exercises.filter { !$0.isArchived }.count))
                        row("mastery.completed", value: String(exercises.filter(\.isArchived).count))
                        row("mastery.daily.results", value: String(results.count))
                        row("mastery.daily.clean", value: String(results.filter(\.clean).count))
                        row("mastery.practice.total", value: Duration.seconds(sessions.reduce(0) { $0 + $1.seconds }).formatted(.time(pattern: .hourMinuteSecond)))
                    }.padding(16).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exercise.name).font(.headline)
                            row("mastery.daily.results", value: String(exercise.results.count))
                            row("mastery.best", value: exercise.bestCleanBPM.map { "\($0) BPM" } ?? "—")
                            row("mastery.target", value: "\(exercise.targetBPM) BPM")
                            row("mastery.practice.total", value: Duration.seconds(exercise.practiceSeconds).formatted(.time(pattern: .hourMinuteSecond)))
                        }.padding(16).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                }.padding(16)
            }
            .background(AppBackgroundView())
            .navigationTitle("mastery.statistics.all")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("mastery.done") { dismiss() } } }
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
