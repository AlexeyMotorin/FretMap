import SwiftUI
import UIKit

struct CustomTuningEditorView: View {
    let presets: [CustomTuningPreset]
    let stringCount: Int
    let noteNames: [String]
    let defaultPitchClasses: [Int]
    let onSave: (CustomTuningPreset) -> Void
    let onDelete: (CustomTuningPreset) -> Void
    let onDismiss: () -> Void

    @State private var editingPresetID: String?
    @State private var draftName = ""
    @State private var draftPitchClasses: [Int] = []
    @FocusState private var isNameFocused: Bool

    private let horizontalContentPadding: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let windowWidth = activeWindowWidth ?? proxy.size.width
            let layoutWidth = min(430, windowWidth)

            ZStack {
                KeyboardDismissTapObserver {
                    dismissKeyboard()
                }
                .frame(width: 0, height: 0)

                AppBackgroundView()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }

                VStack(spacing: 0) {
                    header
                    editorContent
                    actionButtons
                }
                .frame(width: layoutWidth)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .frame(width: windowWidth, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .onAppear {
            resetDraft()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Создать строй")
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        AppColors.control.opacity(0.95),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Отмена")
        }
        .padding(.horizontal, horizontalContentPadding)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var editorContent: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                if !presets.isEmpty {
                    savedTunings
                }

                tuningForm
                allStringsSemitoneControl
            }
            .padding(.horizontal, horizontalContentPadding)
            .padding(.vertical, 18)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in dismissKeyboard() }
        )
    }

    private var savedTunings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сохраненные")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.mutedText)

            ForEach(presets) { preset in
                savedTuningRow(preset)
            }
        }
    }

    private var tuningForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(editingPresetID == nil ? "Новый строй" : "Редактирование")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 14)

            TextField(
                "",
                text: $draftName,
                prompt: Text("Введите название строя")
                    .foregroundColor(Color.gray.opacity(0.85))
            )
            .textFieldStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .focused($isNameFocused)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                AppColors.control.opacity(0.9),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )

            ForEach(0..<stringCount, id: \.self) { visualIndex in
                let storageIndex = stringCount - 1 - visualIndex
                stringPitchRow(visualIndex: visualIndex, storageIndex: storageIndex)
            }
        }
        .padding(.vertical, 12)
        .background(
            AppColors.panel.opacity(0.95),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func stringPitchRow(visualIndex: Int, storageIndex: Int) -> some View {
        HStack(spacing: 10) {
            Text("Струна \(visualIndex + 1): \(pitchName(at: storageIndex))")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer()

            semitoneButton(
                systemName: "arrow.down",
                label: "Опустить струну \(visualIndex + 1)"
            ) {
                shiftPitch(at: storageIndex, by: -1)
            }

            semitoneButton(
                systemName: "arrow.up",
                label: "Поднять струну \(visualIndex + 1)"
            ) {
                shiftPitch(at: storageIndex, by: 1)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            AppColors.control.opacity(0.9),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func savedTuningRow(_ preset: CustomTuningPreset) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                Text(tuningSummary(for: preset.pitchClasses))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                edit(preset)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)

            Button {
                onDelete(preset)
                if editingPresetID == preset.id {
                    resetDraft()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(10)
        .background(
            AppColors.control.opacity(0.55),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private var allStringsSemitoneControl: some View {
        HStack(spacing: 10) {
            Text("Все струны")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            semitoneButton(systemName: "arrow.down", label: "Опустить все") {
                shiftAllPitches(by: -1)
            }

            semitoneButton(systemName: "arrow.up", label: "Поднять все") {
                shiftAllPitches(by: 1)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            AppColors.control.opacity(0.72),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func semitoneButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withoutAnimation(action)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 42, height: 36)
                .background(
                    AppColors.panel.opacity(0.9),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: resetDraft) {
                Text("Сбросить")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.bordered)

            Button(action: saveDraft) {
                Text("OK")
                    .font(.system(.subheadline, design: .rounded).weight(.black))
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, horizontalContentPadding)
        .padding(.bottom, 20)
        .padding(.top, 12)
    }

    private var activeWindowWidth: CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .bounds.width
    }

    private func normalizedPitchClasses(_ pitches: [Int]) -> [Int] {
        var normalized = Array(pitches.prefix(stringCount))
        while normalized.count < stringCount {
            let fallbackIndex = normalized.count
            let fallbackPitch = defaultPitchClasses.indices.contains(fallbackIndex)
                ? defaultPitchClasses[fallbackIndex]
                : 0
            normalized.append(fallbackPitch)
        }
        return normalized.map { min(max($0, 0), 11) }
    }

    private func pitchName(at index: Int) -> String {
        let pitches = normalizedPitchClasses(draftPitchClasses)
        guard pitches.indices.contains(index), noteNames.indices.contains(pitches[index]) else {
            return ""
        }
        return noteNames[pitches[index]]
    }

    private func shiftPitch(at index: Int, by semitones: Int) {
        draftPitchClasses = normalizedPitchClasses(draftPitchClasses)
        guard draftPitchClasses.indices.contains(index) else { return }
        draftPitchClasses[index] = shiftedPitch(draftPitchClasses[index], by: semitones)
    }

    private func shiftAllPitches(by semitones: Int) {
        draftPitchClasses = normalizedPitchClasses(draftPitchClasses)
            .map { shiftedPitch($0, by: semitones) }
    }

    private func shiftedPitch(_ pitch: Int, by semitones: Int) -> Int {
        (pitch + semitones + 120) % 12
    }

    private func tuningSummary(for pitchClasses: [Int]) -> String {
        pitchClasses.reversed().compactMap { pitch in
            noteNames.indices.contains(pitch) ? noteNames[pitch] : nil
        }
        .joined(separator: " ")
    }

    private func edit(_ preset: CustomTuningPreset) {
        editingPresetID = preset.id
        draftName = preset.name
        draftPitchClasses = normalizedPitchClasses(preset.pitchClasses)
    }

    private func resetDraft() {
        editingPresetID = nil
        draftName = ""
        draftPitchClasses = normalizedPitchClasses(defaultPitchClasses)
    }

    private func saveDraft() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        onSave(
            CustomTuningPreset(
                id: editingPresetID ?? UUID().uuidString,
                name: name,
                stringCount: stringCount,
                pitchClasses: normalizedPitchClasses(draftPitchClasses)
            )
        )
        resetDraft()
        isNameFocused = true
    }

    private func dismissKeyboard() {
        isNameFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            updates()
        }
    }
}
