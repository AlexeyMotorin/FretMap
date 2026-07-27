import Foundation

struct TuningCatalog {
    private let builtInTunings: [TuningPreset]

    init(builtInTunings: [TuningPreset] = TuningPreset.all) {
        self.builtInTunings = builtInTunings
    }

    func compatibleTunings(stringCount: Int) -> [TuningPreset] {
        builtInTunings.filter { $0.stringCount == stringCount }
    }

    func customTunings(
        stringCount: Int,
        from presets: [CustomTuningPreset]
    ) -> [CustomTuningPreset] {
        presets.filter { $0.stringCount == stringCount }
    }

    func selectedCustomTuning(
        id: String?,
        stringCount: Int,
        from presets: [CustomTuningPreset]
    ) -> CustomTuningPreset? {
        guard let id else { return nil }
        return presets.first { $0.id == id && $0.stringCount == stringCount }
    }

    func resolveTuning(
        stringCount: Int,
        builtInID: String,
        customID: String?,
        customPresets: [CustomTuningPreset],
        noteNames: [String]
    ) -> TuningPreset {
        if let custom = selectedCustomTuning(
            id: customID,
            stringCount: stringCount,
            from: customPresets
        ) {
            return TuningPreset.custom(
                id: menuID(forCustomTuningID: custom.id),
                name: custom.name,
                stringCount: stringCount,
                pitchClasses: custom.pitchClasses,
                noteNames: noteNames
            )
        }

        let compatible = compatibleTunings(stringCount: stringCount)
        return compatible.first { $0.id == builtInID } ?? compatible[0]
    }

    func defaultPitchClasses(stringCount: Int) -> [Int] {
        compatibleTunings(stringCount: stringCount)
            .first?
            .strings
            .map(\.pitchClass) ?? Array(repeating: 0, count: stringCount)
    }

    func menuID(forCustomTuningID id: String) -> String {
        "custom:\(id)"
    }

    func customTuningID(fromMenuID menuID: String) -> String? {
        let prefix = "custom:"
        guard menuID.hasPrefix(prefix) else { return nil }
        return String(menuID.dropFirst(prefix.count))
    }
}
