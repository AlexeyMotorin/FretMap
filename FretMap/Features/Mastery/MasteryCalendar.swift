import SwiftUI

struct MasteryCalendar: View {
    @Binding var selectedDate: Date
    let practiceDays: Set<Date>
    let today: Date
    @State private var month = Date()
    private var calendar: Calendar { .current }
    private var monthStart: Date { calendar.dateInterval(of: .month, for: month)?.start ?? calendar.startOfDay(for: month) }
    private var offset: Int { (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7 }
    private var dayCount: Int { calendar.range(of: .day, in: .month, for: month)?.count ?? 0 }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("mastery.month.previous")
                Spacer()
                Text(month, format: .dateTime.month(.wide).year()).font(.headline)
                Spacer()
                Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(calendar.isDate(month, equalTo: today, toGranularity: .month))
                    .accessibilityLabel("mastery.month.next")
            }
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { index in
                    Text(calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7])
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                }
                ForEach(0..<((offset + dayCount + 6) / 7), id: \.self) { week in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { weekday in
                            let index = week * 7 + weekday
                    if index < offset || index >= offset + dayCount {
                        Color.clear.frame(maxWidth: .infinity).frame(height: 44)
                    } else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: monthStart) ?? monthStart
                        let trained = practiceDays.contains(calendar.startOfDay(for: date))
                        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                        Button { selectedDate = date } label: {
                            VStack(spacing: 3) {
                                Text(String(index - offset + 1))
                                Circle().fill(selected ? Color.white : Color.accentColor)
                                    .frame(width: 5, height: 5).opacity(trained ? 1 : 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(selected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                        }.buttonStyle(.plain)
                            .disabled(date > today)
                            .opacity(date > today ? 0.3 : 1)
                            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                            .accessibilityValue(trained ? L10n.string("mastery.day.trained") : "")
                    }
                }
                    }
                }
            }
        }.buttonStyle(.borderless)
        .onAppear { month = selectedDate }
    }
    private func move(_ amount: Int) {
        if let next = calendar.date(byAdding: .month, value: amount, to: monthStart) { month = next }
    }
}
