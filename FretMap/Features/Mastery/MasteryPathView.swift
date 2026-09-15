import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO

struct MasteryPathView: View {
    let onBack: () -> Void
    @StateObject private var store = MasteryStore()
    @State private var dailyStatistics = false
    @State private var adding = false
    @State private var showingArchive = false
    @State private var editingExercise: MasteryExercise?
    @State private var deletingExercise: MasteryExercise?
    @State private var confirmingDelete = false
    @State private var category = ""
    @State private var search = ""
    @State private var newestFirst = true
    @ScaledMetric(relativeTo: .headline) private var cardTitleHeight = 44

    private var filtered: [MasteryExercise] {
        let items = store.exercises.filter {
            $0.isArchived == showingArchive &&
            (category.isEmpty || $0.category == category) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.comment.localizedCaseInsensitiveContains(search))
        }
        return items.sorted {
            if newestFirst { return $0.createdAt > $1.createdAt }
            return ($0.latest?.date ?? $0.createdAt) > ($1.latest?.date ?? $1.createdAt)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("mastery.title").font(.largeTitle.bold())
                            Text("mastery.subtitle").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { adding = true } label: {
                            Image(systemName: "plus").font(.title2.bold()).frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("mastery.add")
                    }
                    HStack(spacing: 12) {
                        Picker("mastery.workspace", selection: $showingArchive) {
                            Text("mastery.active").tag(false)
                            Text("mastery.archive").tag(true)
                        }.pickerStyle(.segmented)
                        Button { dailyStatistics = true } label: {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.rootText)
                        .accessibilityLabel("mastery.daily.title")
                    }
                    TextField("mastery.search", text: $search).textFieldStyle(.roundedBorder)
                    HStack {
                        Picker("mastery.category", selection: $category) {
                            Text("mastery.all").tag("")
                            ForEach(store.categories, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.menu)
                        Spacer()
                        Button { newestFirst.toggle() } label: {
                            Label(newestFirst ? "mastery.newest" : "mastery.recent", systemImage: "arrow.up.arrow.down")
                        }.font(.caption)
                    }
                    if filtered.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "chart.xyaxis.line").font(.system(size: 44)).foregroundStyle(AppColors.rootText)
                            Text(showingArchive ? "mastery.archive.empty" : (store.exercises.isEmpty ? "mastery.empty" : "mastery.no.matches")).font(.headline)
                            if store.exercises.isEmpty && !showingArchive {
                                Button("mastery.add") { adding = true }.buttonStyle(.borderedProminent)
                            }
                        }.frame(maxWidth: .infinity).padding(.vertical, 60)
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 14) {
                        ForEach(filtered) { exercise in
                            NavigationLink {
                                MasteryExerciseView(store: store, exerciseID: exercise.id)
                            } label: { exerciseCard(exercise) }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button { editingExercise = exercise } label: {
                                    Label("mastery.edit", systemImage: "pencil")
                                }
                                Button {
                                    store.setArchived(!exercise.isArchived, id: exercise.id)
                                } label: {
                                    Label(exercise.isArchived ? "mastery.reactivate" : "mastery.complete",
                                          systemImage: exercise.isArchived ? "arrow.uturn.backward" : "checkmark.circle")
                                }
                                Button(role: .destructive) {
                                    deletingExercise = exercise
                                    confirmingDelete = true
                                } label: { Label("mastery.delete", systemImage: "trash") }
                            }
                        }
                    }
                }.padding(16)
            }
            .background(AppBackgroundView())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    ModeBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .fullScreenCover(isPresented: $adding, onDismiss: { if !store.exercises.isEmpty { showingArchive = false } }) {
                MasteryEditor(store: store, exercise: nil)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $dailyStatistics) { MasteryDailyStatistics(store: store) }
            .sheet(item: $editingExercise) { MasteryEditor(store: store, exercise: $0) }
            .alert("mastery.delete.title", isPresented: $confirmingDelete) {
                Button("mastery.delete", role: .destructive) {
                    if let deletingExercise { store.delete(deletingExercise.id) }
                    deletingExercise = nil
                }
                Button("mastery.cancel", role: .cancel) { deletingExercise = nil }
            } message: { Text("mastery.delete.message") }
            .alert("mastery.error", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
            .onChange(of: store.categories) { categories in
                if !category.isEmpty && !categories.contains(category) { category = "" }
            }
        }
        .tint(AppColors.rootText)
    }

    private func exerciseCard(_ exercise: MasteryExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let photo = exercise.photos.first {
                    MasteryThumbnail(url: store.photoURL(photo))
                } else {
                    Image(systemName: "guitars.fill").font(.system(size: 34))
                        .foregroundStyle(AppColors.rootText).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 100).frame(maxWidth: .infinity)
            .background(AppColors.control).clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if exercise.isArchived {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(6)
                        .background(AppColors.panel, in: Circle())
                        .padding(6)
                        .accessibilityLabel("mastery.completed")
                }
            }
            Text(exercise.difficulty.map { L10n.string($0.localizationKey) } ?? " ")
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                .accessibilityHidden(exercise.difficulty == nil)
            Text(exercise.name).font(.headline).lineLimit(2)
                .frame(height: cardTitleHeight, alignment: .topLeading)
            Text(exercise.category.isEmpty ? L10n.string("mastery.uncategorized") : exercise.category)
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.latest.map { "\($0.bpm)" } ?? "—").font(.title2.bold())
                Text("→ \(exercise.targetBPM) BPM").font(.caption).foregroundStyle(.secondary)
            }.minimumScaleFactor(0.7).lineLimit(1)
            ProgressView(value: exercise.progress)
            Group {
                if let date = exercise.latest?.date {
                    Text(date, style: .date)
                } else {
                    Text("mastery.no.results")
                }
            }
            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(12).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MasteryThumbnail: View {
    let url: URL
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Image(systemName: "photo").foregroundStyle(.secondary) }
        }
        .task(id: url) {
            let loaded = await Task.detached(priority: .utility) {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceThumbnailMaxPixelSize: 600,
                        kCGImageSourceCreateThumbnailWithTransform: true
                      ] as CFDictionary) else { return Optional<UIImage>.none }
                return UIImage(cgImage: thumbnail)
            }.value
            if !Task.isCancelled { image = loaded }
        }
    }
}

private struct MasteryEditor: View {
    @ObservedObject var store: MasteryStore
    let exercise: MasteryExercise?
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var target = "120"
    @State private var category = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("mastery.name", text: $name)
                    HStack {
                        Text("mastery.target")
                        TextField("BPM", text: $target).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    Text("mastery.range").font(.caption).foregroundStyle(.secondary)
                }
                Section("mastery.category") {
                    TextField("mastery.category.new", text: $category)
                    if !store.categories.isEmpty {
                        Picker("mastery.category.existing", selection: $category) {
                            Text("mastery.uncategorized").tag("")
                            if !category.isEmpty && !store.categories.contains(category) { Text(category).tag(category) }
                            ForEach(store.categories, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
            }
            .navigationTitle(exercise == nil ? "mastery.add" : "mastery.edit")
            .navigationBarTitleDisplayMode(.inline)
            .masteryKeyboardDismiss()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("mastery.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("mastery.save") {
                        guard let bpm = Int(target) else { return }
                        var value = exercise.flatMap { original in store.exercises.first { $0.id == original.id } }
                            ?? MasteryExercise(name: name, targetBPM: bpm)
                        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        value.targetBPM = bpm
                        value.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.save(value) { dismiss() }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(20...400).contains(Int(target) ?? 0))
                }
            }
            .onAppear { if let exercise { name = exercise.name; target = "\(exercise.targetBPM)"; category = exercise.category } }
            .alert("mastery.error", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }
}

private struct MasteryExerciseView: View {
    @ObservedObject var store: MasteryStore
    let exerciseID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var practice = MasteryPractice()
    @State private var editing = false
    @State private var deleting = false
    @State private var history = false
    @State private var bpm = "80"
    @State private var clean = true
    @State private var resultNote = ""
    @State private var savedResult: MasteryResult?
    @State private var savedResultNumber = 0
    @State private var minutes = 5
    @State private var showingTimer = false
    @State private var metroBPM = 80
    @State private var beats = 4
    @State private var ratingExercise = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var importing = false
    @State private var camera = false
    @State private var pickingPDF = false
    @State private var selectedPDF: MasteryPDF?
    @State private var importingPDF = false
    @State private var selectedPhoto: PhotoSelection?
    private struct PhotoSelection: Identifiable { let id: String }
    private var exercise: MasteryExercise? { store.exercises.first { $0.id == exerciseID } }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summary(exercise)
                        Button { ratingExercise = true } label: {
                            HStack {
                                Label("mastery.difficulty", systemImage: "slider.horizontal.3")
                                Spacer()
                                Text(exercise.difficulty.map { L10n.string($0.localizationKey) } ?? L10n.string("mastery.difficulty.choose"))
                            }.frame(minHeight: 44)
                        }
                        .confirmationDialog("mastery.difficulty", isPresented: $ratingExercise, titleVisibility: .visible) {
                            ForEach(ExerciseDifficulty.allCases, id: \.self) { difficulty in
                                Button(L10n.string(difficulty.localizationKey)) {
                                    store.update(exerciseID) { $0.difficulty = difficulty }
                                }
                            }
                            Button("mastery.cancel", role: .cancel) { }
                        }
                        photos(exercise)
                        resultEntry
                        chart(exercise)
                        notes(exercise)
                        timerPanel
                        metronomePanel
                        Text("mastery.practice.total").font(.caption).foregroundStyle(.secondary)
                        Text(Duration.seconds(exercise.practiceSeconds).formatted(.time(pattern: .hourMinuteSecond)))
                        Button {
                            practice.stopAll()
                            if store.setArchived(!exercise.isArchived, id: exerciseID) { dismiss() }
                        } label: {
                            Label(exercise.isArchived ? "mastery.reactivate" : "mastery.complete",
                                  systemImage: exercise.isArchived ? "arrow.uturn.backward" : "checkmark.circle")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.bordered)
                    }.padding(16)
                }.scrollDismissesKeyboard(.interactively)
                .masteryKeyboardDismiss()
                .background(AppBackgroundView())
                .navigationTitle(exercise.name).navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("mastery.edit") { editing = true }
                            Button("mastery.delete", role: .destructive) { deleting = true }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
                .sheet(isPresented: $editing) { MasteryEditor(store: store, exercise: self.exercise) }
                .sheet(isPresented: $history) { historySheet }
                .sheet(isPresented: $camera) {
                    MasteryCamera { image in
                        if let image { store.addPhoto(image, to: exerciseID) }
                        camera = false
                    }.ignoresSafeArea()
                }
                .fileImporter(isPresented: $pickingPDF, allowedContentTypes: [.pdf]) { result in
                    switch result {
                    case .success(let url):
                        importingPDF = true
                        Task { @MainActor in
                            defer { importingPDF = false }
                            do {
                                let data = try await Task.detached(priority: .userInitiated) {
                                    try MasteryPDFReader.read(url)
                                }.value
                                try store.addPDF(data: data, name: url.lastPathComponent, to: exerciseID)
                            } catch { store.error = error.localizedDescription }
                        }
                    case .failure(let error): store.error = error.localizedDescription
                    }
                }
                .fullScreenCover(isPresented: $showingTimer) {
                    MasteryTimerScreen(practice: practice, exerciseName: exercise.name) {
                        practice.pauseTimer()
                        showingTimer = false
                    }
                }
                .fullScreenCover(item: $selectedPDF) { pdf in
                    MasteryPDFViewer(url: store.photoURL(pdf.id), name: pdf.name)
                }
                .fullScreenCover(item: $selectedPhoto) { selection in
                    MasteryPhotoViewer(url: store.photoURL(selection.id))
                }
                .alert("mastery.delete.title", isPresented: $deleting) {
                    Button("mastery.delete", role: .destructive) {
                        practice.stopAll()
                        store.delete(exerciseID)
                        if self.exercise == nil { dismiss() }
                    }
                    Button("mastery.cancel", role: .cancel) { }
                } message: { Text("mastery.delete.message") }
            }
        }
        .onAppear {
            bpm = "\(exercise?.latest?.bpm ?? 80)"
            metroBPM = min(240, max(30, exercise?.latest?.bpm ?? 80))
            practice.onSession = { seconds in
                store.update(exerciseID) { $0.sessions.append(MasterySession(seconds: seconds)) }
            }
        }
        .onDisappear { if !showingTimer { practice.stopAll() } }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                practice.pauseTimer()
                practice.stopMetronome()
                showingTimer = false
            }
        }
        .task(id: photoItems) {
            guard !photoItems.isEmpty else { return }
            importing = true
            for item in photoItems {
                if Task.isCancelled { break }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                        store.error = L10n.string("mastery.photo.error"); continue
                    }
                    if !Task.isCancelled { store.addPhoto(image, to: exerciseID) }
                } catch { if !Task.isCancelled { store.error = L10n.string("mastery.photo.error") } }
            }
            importing = false
            photoItems = []
        }
        .alert("mastery.error", isPresented: Binding(get: { practice.error != nil || store.error != nil }, set: { if !$0 { practice.error = nil; store.error = nil } })) {
            Button("OK") { practice.error = nil; store.error = nil }
        } message: { Text(practice.error ?? store.error ?? "") }
    }

    private func summary(_ exercise: MasteryExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.category.isEmpty ? L10n.string("mastery.uncategorized") : exercise.category).font(.subheadline).foregroundStyle(.secondary)
            HStack {
                metric("mastery.current", value: exercise.latest.map { "\($0.bpm)" } ?? "—")
                Spacer()
                metric("mastery.best", value: exercise.bestCleanBPM.map(String.init) ?? "—", achieved: (exercise.bestCleanBPM ?? 0) >= exercise.targetBPM)
                Spacer()
                metric("mastery.target", value: "\(exercise.targetBPM)")
            }
            ProgressView(value: exercise.progress)
            Text(exercise.progress >= 1 ? "mastery.achieved" : "mastery.progress.hint").font(.caption).foregroundStyle(.secondary)
        }.masteryPanel()
    }

    private func metric(_ title: LocalizedStringKey, value: String, achieved: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(achieved ? .system(size: 24, weight: .bold) : .title2.bold())
                .foregroundStyle(achieved ? Color.green : AppColors.primaryText)
            Text("BPM").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func photos(_ exercise: MasteryExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mastery.photos").font(.headline)
            if exercise.photos.isEmpty { Text("mastery.photos.hint").font(.caption).foregroundStyle(.secondary) }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(exercise.photos, id: \.self) { name in
                        Button { selectedPhoto = PhotoSelection(id: name) } label: {
                            MasteryThumbnail(url: store.photoURL(name)).frame(width: 180, height: 120)
                        }.accessibilityLabel("mastery.photos")
                        .contextMenu {
                            Button("mastery.delete", role: .destructive) { store.removePhoto(name, from: exerciseID) }
                        }
                    }
                }
            }
            if exercise.photos.count < 8 {
                HStack {
                    PhotosPicker(selection: $photoItems, maxSelectionCount: 8 - exercise.photos.count, matching: .images) {
                        Label("mastery.photo.add", systemImage: "photo.badge.plus")
                    }.disabled(importing)
                    Spacer()
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { camera = true } label: { Image(systemName: "camera").frame(width: 44, height: 44) }
                            .accessibilityLabel("mastery.camera")
                    }
                    if importing { ProgressView() }
                }
            }
            ForEach(exercise.attachedPDFs) { pdf in
                Button { selectedPDF = pdf } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.richtext").font(.title2)
                        Text(pdf.name).lineLimit(2).multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }.frame(minHeight: 44)
                }.contextMenu {
                    Button("mastery.delete", role: .destructive) { store.removePDF(pdf.id, from: exerciseID) }
                }
            }
            if exercise.attachedPDFs.isEmpty {
                Button { pickingPDF = true } label: { Label("mastery.pdf.add", systemImage: "doc.badge.plus") }
                    .disabled(importingPDF)
            }
            if importingPDF { ProgressView() }
            Text("mastery.pdf.hint").font(.caption).foregroundStyle(.secondary)
        }.masteryPanel()
    }

    private var resultEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("mastery.result").font(.headline)
                Spacer()
                Button { history = true } label: { Label("mastery.history", systemImage: "clock.arrow.circlepath") }.font(.caption)
            }
            HStack {
                TextField("BPM", text: $bpm).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                Stepper("BPM", value: Binding(get: { Int(bpm) ?? 80 }, set: { bpm = "\($0)" }), in: 20...400).labelsHidden()
            }
            Toggle("mastery.clean", isOn: $clean)
            TextField("mastery.result.note", text: $resultNote, axis: .vertical).lineLimit(2...4)
            Button("mastery.record") {
                guard let value = Int(bpm), (20...400).contains(value) else { return }
                let result = MasteryResult(bpm: value, clean: clean, note: resultNote)
                store.update(exerciseID) { $0.results.append(result) }
                if let exercise, exercise.results.contains(where: { $0.id == result.id }) {
                    resultNote = ""
                    savedResult = result
                    savedResultNumber = exercise.results.count
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    UIAccessibility.post(notification: .announcement,
                                         argument: "\(L10n.string("mastery.result.saved")): \(value) BPM")
                }
            }.buttonStyle(.borderedProminent).disabled(!(20...400).contains(Int(bpm) ?? 0))
            if let savedResult {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("mastery.result.saved").font(.subheadline.weight(.semibold))
                        Text("№\(savedResultNumber) · \(savedResult.bpm) BPM · \(savedResult.date.formatted(date: .omitted, time: .standard))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button("mastery.history") { history = true }.font(.caption)
                }
                .padding(12)
                .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
        }.masteryPanel()
    }

    private func chart(_ exercise: MasteryExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mastery.chart").font(.headline)
            if exercise.results.isEmpty {
                Text("mastery.chart.empty").foregroundStyle(.secondary)
            } else {
                MasteryProgressPlot(results: exercise.results, target: exercise.targetBPM)
                    .frame(height: 210)
                Text("mastery.chart.legend").font(.caption).foregroundStyle(.secondary)
            }
        }.masteryPanel()
    }

    private func notes(_ exercise: MasteryExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("mastery.notes").font(.headline)
            TextField("mastery.notes.hint", text: Binding(get: { self.exercise?.comment ?? "" }, set: { value in
                store.update(exerciseID) { $0.comment = value }
            }), axis: .vertical).lineLimit(3...8)
        }.masteryPanel()
    }

    private func openTimer() {
        if practice.remaining <= 0 { practice.resetTimer(minutes: minutes) }
        showingTimer = true
    }

    private var timerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mastery.timer").font(.headline)
            MasteryWheelControl(title: "mastery.timer", value: $minutes, range: 1...120, unit: L10n.string("mastery.minutes"))
                .disabled(practice.running)
            Button(action: openTimer) {
                Text(Duration.seconds(practice.remaining.rounded(.up)).formatted(.time(pattern: .minuteSecond)))
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
            }.buttonStyle(.plain).accessibilityLabel("mastery.timer.open")
            HStack {
                Button(practice.hasPausedTimer ? "mastery.resume" : "mastery.start", action: openTimer)
                    .buttonStyle(.borderedProminent)
                Button("mastery.timer.reset") { practice.resetTimer(minutes: minutes) }.buttonStyle(.bordered)
            }
            Text("mastery.timer.hint").font(.caption).foregroundStyle(.secondary)
        }.masteryPanel()
        .onChange(of: minutes) { practice.resetTimer(minutes: $0) }
    }

    private var metronomePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mastery.metronome").font(.headline)
            MasteryWheelControl(title: "mastery.metronome", value: $metroBPM, range: 30...240, unit: "BPM")
            Button("mastery.use.bpm") { if let value = Int(bpm) { metroBPM = min(240, max(30, value)) } }
                .font(.caption)
            Picker("mastery.beats", selection: $beats) {
                ForEach(1...7, id: \.self) { Text("\($0)").tag($0) }
            }.pickerStyle(.segmented)
            Text("mastery.beats.hint").font(.caption).foregroundStyle(.secondary)
            Button(practice.metronomePlaying ? "mastery.stop" : "mastery.start") {
                if practice.metronomePlaying { practice.stopMetronome() }
                else { practice.startMetronome(bpm: metroBPM, beats: beats) }
            }.buttonStyle(.borderedProminent)
        }.masteryPanel()
        .onChange(of: metroBPM) { value in
            bpm = String(value)
            if practice.metronomePlaying {
                practice.startMetronome(bpm: value, beats: beats)
            }
        }
        .onChange(of: beats) { _ in if practice.metronomePlaying { practice.startMetronome(bpm: metroBPM, beats: beats) } }
    }

    private var historySheet: some View {
        NavigationStack {
            List {
                Section("mastery.history") {
                    ForEach((exercise?.results ?? []).sorted { $0.date > $1.date }) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(result.bpm) BPM").bold()
                                Spacer()
                                Text(result.clean ? "mastery.clean" : "mastery.attempt").font(.caption)
                            }
                            Text(result.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                            if !result.note.isEmpty { Text(result.note).font(.subheadline) }
                        }.swipeActions {
                            Button("mastery.delete", role: .destructive) {
                                store.update(exerciseID) { $0.results.removeAll { $0.id == result.id } }
                            }
                        }
                    }
                    if exercise?.results.isEmpty == true { Text("mastery.no.results") }
                }
                Section("mastery.sessions") {
                    ForEach((exercise?.sessions ?? []).sorted { $0.date > $1.date }) { session in
                        VStack(alignment: .leading) {
                            Text(Duration.seconds(session.seconds).formatted(.time(pattern: .hourMinuteSecond)))
                            Text(session.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.navigationTitle("mastery.history")
                .toolbar { Button("mastery.done") { history = false } }
        }
    }
}

private extension View {
    func masteryKeyboardDismiss() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("mastery.done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    func masteryPanel() -> some View {
        padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MasteryPhotoViewer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            MasteryZoomImage(url: url).background(Color.black)
                .toolbar { Button("mastery.done") { dismiss() } }
        }
    }
}

private struct MasteryZoomImage: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 5
        scroll.delegate = context.coordinator
        let image = context.coordinator.image
        image.image = UIImage(contentsOfFile: url.path)
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(image)
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            image.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            image.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            image.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            image.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        return scroll
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) { }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let image = UIImageView()
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { image }
    }
}

private struct MasteryCamera: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
        }
    }
}

private struct MasteryProgressPlot: View {
    let results: [MasteryResult]
    let target: Int
    private var sorted: [MasteryResult] { results.sorted { $0.date < $1.date } }

    var body: some View {
        GeometryReader { proxy in
            let values = sorted
            let upper = Double(max(target + 20, (values.map(\.bpm).max() ?? 0) + 20))
            let width = max(1, proxy.size.width - 46)
            let height = max(1, proxy.size.height - 32)
            let first = values.first?.date ?? Date()
            let duration = max(1, (values.last?.date ?? first).timeIntervalSince(first))
            let point: (MasteryResult) -> CGPoint = { result in
                let fraction = values.count == 1 ? 0.5 : result.date.timeIntervalSince(first) / duration
                return CGPoint(x: 38 + fraction * width, y: height * (1 - Double(result.bpm) / upper))
            }
            ZStack(alignment: .topLeading) {
                ForEach(0..<5, id: \.self) { index in
                    let value = upper * Double(index) / 4
                    let y = height * (1 - Double(index) / 4)
                    Path { path in
                        path.move(to: CGPoint(x: 38, y: y))
                        path.addLine(to: CGPoint(x: 38 + width, y: y))
                    }.stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    Text("\(Int(value))").font(.caption2).foregroundStyle(.secondary)
                        .position(x: 15, y: y)
                }
                Path { path in
                    let y = height * (1 - Double(target) / upper)
                    path.move(to: CGPoint(x: 38, y: y))
                    path.addLine(to: CGPoint(x: 38 + width, y: y))
                }.stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                Path { path in
                    for (index, result) in values.enumerated() {
                        if index == 0 { path.move(to: point(result)) }
                        else { path.addLine(to: point(result)) }
                    }
                }.stroke(AppColors.rootText, lineWidth: 2)
                ForEach(values) { result in
                    Circle().fill(result.clean ? Color.green : Color.orange)
                        .frame(width: 8, height: 8).position(point(result))
                }
                HStack {
                    Text(first, format: .dateTime.day().month())
                    Spacer()
                    if let last = values.last, values.count > 1 { Text(last.date, format: .dateTime.day().month()) }
                }.font(.caption2).foregroundStyle(.secondary)
                    .frame(width: width).offset(x: 38, y: height + 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("mastery.chart")
        .accessibilityValue(sorted.map { "\($0.date.formatted(date: .abbreviated, time: .shortened)): \($0.bpm) BPM" }.joined(separator: ", "))
    }
}

private struct MasteryWheelControl: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    @State private var showing = false
    @State private var draft = 0

    var body: some View {
        Button {
            draft = value
            showing = true
        } label: {
            HStack {
                Text("\(value) \(unit)").font(.title3.monospacedDigit().bold())
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }.frame(minHeight: 44)
        }
        .accessibilityLabel(title)
        .accessibilityValue("\(value) \(unit)")
        .sheet(isPresented: $showing) {
            NavigationStack {
                Picker(title, selection: $draft) {
                    ForEach(Array(range), id: \.self) { number in
                        Text("\(number) \(unit)").tag(number)
                    }
                }.pickerStyle(.wheel)
                    .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("mastery.cancel") { showing = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("mastery.done") { value = draft; showing = false }
                        }
                    }
            }.presentationDetents([.height(300)])
        }
    }
}
