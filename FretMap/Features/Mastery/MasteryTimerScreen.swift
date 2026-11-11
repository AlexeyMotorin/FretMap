import SwiftUI

struct MasteryTimerScreen: View {
    @ObservedObject var practice: MasteryPractice
    let exerciseName: String
    let onClose: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousIdleSetting = false

    var body: some View {
        GeometryReader { proxy in
            let diameter = max(120, min(proxy.size.width - 48, proxy.size.height - 200, 360))
            VStack(spacing: 20) {
                Text(exerciseName).font(.headline).lineLimit(2).multilineTextAlignment(.center)
                Spacer(minLength: 0)
                ZStack {
                    Circle().stroke(Color.white.opacity(0.10), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: min(1, max(0, practice.remaining / max(1, practice.timerDuration))))
                        .stroke(AppColors.rootText, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 10) {
                        Text(Duration.seconds(practice.remaining.rounded(.up)).formatted(.time(pattern: .minuteSecond)))
                            .font(.system(size: diameter * 0.20, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                        Text(practice.remaining <= 0 ? "mastery.timer.finished" : "mastery.timer")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }.frame(width: diameter, height: diameter)
                Spacer(minLength: 0)
                Button(practice.remaining <= 0 ? "mastery.done" : "mastery.pause", action: onClose)
                    .buttonStyle(.borderedProminent).controlSize(.large)
                Text("mastery.timer.pause.hint").font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppBackgroundView())
        .interactiveDismissDisabled()
        .onAppear {
            previousIdleSetting = UIApplication.shared.isIdleTimerDisabled
            practice.startTimer()
            UIApplication.shared.isIdleTimerDisabled = practice.running
        }
        .onChange(of: practice.running) { running in
            UIApplication.shared.isIdleTimerDisabled = running ? true : previousIdleSetting
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                UIApplication.shared.isIdleTimerDisabled = previousIdleSetting
                onClose()
            }
        }
        .onDisappear {
            practice.pauseTimer()
            UIApplication.shared.isIdleTimerDisabled = previousIdleSetting
        }
    }
}
