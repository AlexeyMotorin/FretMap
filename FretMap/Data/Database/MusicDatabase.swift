import Foundation

enum MusicDatabase {
    static func popularProgressions(for scale: ScalePattern) -> [PopularProgression] {
        popularProgressionsByScale[scale.id] ?? popularProgressionsByScale[ScalePattern.ionian.id] ?? []
    }

    static var allPopularProgressions: [PopularProgression] {
        ["ionian", "aeolian", "dorian", "phrygian", "lydian", "mixolydian", "locrian"]
            .flatMap { popularProgressionsByScale[$0] ?? [] }
    }

    private static let popularProgressionsByScale: [String: [PopularProgression]] = [
        "ionian": [
            progression("ionian-pop-axis", "Поп-ось", "Beginner", ["I", "V", "vi", "IV"], 5, .green),
            progression("ionian-pachelbel", "Канонная цепочка", "Beginner", ["I | V", "vi | iii", "IV | I", "IV | V"], 5, .yellow),
            progression("ionian-doo-wop", "Magic changes", "Beginner", ["I", "vi", "IV", "V"], 4, .blue),
            progression("ionian-step-down", "Бас вниз", "Intermediate", ["I", "V/7", "vi", "I/5", "IV"], 4, .green),
            progression("ionian-secondary", "V/vi в обороте", "Intermediate", ["I", "V/vi", "vi", "IV", "V"], 3, .red, usesBorrowedHarmony: true),
            progression("ionian-borrowed-vii", "Каденция через bVII", "Advanced", ["I", "bVII", "IV", "I"], 3, .yellow, usesBorrowedHarmony: true),
            progression("ionian-royal-road", "Royal road", "Intermediate", ["IV", "V", "iii", "vi"], 5, .green),
            progression("ionian-jazz-turnaround", "Turnaround", "Intermediate", ["I | vi", "ii | V", "I", "V"], 5, .blue),
            progression("ionian-plagal", "Плагальный круг", "Beginner", ["I", "IV", "I", "V"], 4, .green),
            progression("ionian-gospel", "Госпел-оборот", "Advanced", ["I", "III", "IV", "iv"], 3, .yellow, usesBorrowedHarmony: true)
        ],
        "dorian": [
            progression("dorian-vamp", "Дорийский вамп", "Modal", ["i", "IV", "i", "IV"], 5, .green),
            progression("dorian-backdoor", "i - bVII - IV", "Modal", ["i", "bVII", "IV", "i"], 4, .blue),
            progression("dorian-two-four", "Минорная опора II-IV", "Modal", ["i", "ii", "IV", "i"], 3, .yellow),
            progression("dorian-five-minor", "С мягкой доминантой", "Modal", ["i", "v", "IV", "i"], 3, .red),
            progression("dorian-bright-minor", "Светлый минор", "Modal", ["i", "IV", "bVII", "i"], 5, .green),
            progression("dorian-loop", "Петля i-ii-IV", "Modal", ["i", "ii", "IV", "bVII"], 4, .yellow),
            progression("dorian-six-color", "Краска натуральной 6", "Modal", ["i", "IV", "ii", "i"], 4, .blue),
            progression("dorian-open", "Открытый модальный ход", "Modal", ["i", "bVII", "ii", "IV"], 3, .green)
        ],
        "phrygian": [
            progression("phrygian-half-step", "Фригийский полутон", "Modal", ["i", "bII", "i", "bvii"], 5, .red),
            progression("phrygian-spanish", "Испанский оборот", "Modal", ["i", "bvii", "bVI", "V"], 4, .yellow, usesBorrowedHarmony: true),
            progression("phrygian-bii", "bII как центр тяжести", "Modal", ["i", "bII", "bvii", "i"], 4, .green),
            progression("phrygian-dark", "Темная каденция", "Modal", ["i", "iv", "bII", "i"], 3, .blue),
            progression("phrygian-rock", "Тяжелый рифф", "Modal", ["i", "bII", "bIII", "bII"], 5, .red),
            progression("phrygian-flat-six", "Через bVI", "Modal", ["i", "bVI", "bII", "i"], 4, .yellow),
            progression("phrygian-bounce", "bII-bvii петля", "Modal", ["i", "bII", "bvii", "bII"], 4, .green),
            progression("phrygian-minor-four", "Минорная iv", "Modal", ["i", "iv", "bvii", "bII"], 3, .blue)
        ],
        "lydian": [
            progression("lydian-two", "Лидийская II ступень", "Modal", ["I", "II", "I", "V"], 5, .green),
            progression("lydian-sharp-four", "#iv° как краска", "Modal", ["I", "#iv°", "V", "I"], 4, .yellow),
            progression("lydian-lift", "Подъем через II", "Modal", ["I", "II", "iii", "I"], 3, .blue),
            progression("lydian-wide", "Широкая мажорная петля", "Modal", ["I", "V", "II", "I"], 3, .green),
            progression("lydian-floating", "Парящий центр", "Modal", ["I", "II", "vi", "V"], 5, .green),
            progression("lydian-bright", "Мажорная яркость", "Modal", ["I", "II", "vii", "I"], 4, .yellow),
            progression("lydian-film", "Кинематографичный лидийский", "Modal", ["I", "V", "vi", "II"], 4, .blue),
            progression("lydian-pedal", "Педальный I-II", "Modal", ["I", "II", "I", "II"], 5, .green)
        ],
        "mixolydian": [
            progression("mixolydian-rock", "Рок-каденция bVII-IV", "Modal", ["I", "bVII", "IV", "I"], 5, .green),
            progression("mixolydian-v-minor", "Минорная v", "Modal", ["I", "v", "bVII", "IV"], 4, .blue),
            progression("mixolydian-plagal", "Плагальная петля", "Modal", ["I", "IV", "bVII", "I"], 4, .yellow),
            progression("mixolydian-cadence", "Возврат через bVII", "Modal", ["I", "bVII", "I", "V"], 3, .red, usesBorrowedHarmony: true),
            progression("mixolydian-blues-rock", "Блюз-рок", "Modal", ["I", "IV", "I", "bVII"], 5, .green),
            progression("mixolydian-country", "Кантри-оборот", "Modal", ["I", "bVII", "IV", "V"], 4, .yellow, usesBorrowedHarmony: true),
            progression("mixolydian-vamp", "I-bVII вамп", "Modal", ["I", "bVII", "I", "bVII"], 5, .blue),
            progression("mixolydian-soft", "Мягкий миксолидийский", "Modal", ["I", "v", "IV", "I"], 4, .green)
        ],
        "aeolian": [
            progression("aeolian-pop-minor", "Минорная поп-ось", "Minor", ["i", "bVI", "bIII", "bVII"], 5, .green),
            progression("aeolian-falling", "Нисходящая цепочка", "Minor", ["i", "bVII", "bVI", "bVII"], 5, .yellow),
            progression("aeolian-subdominant", "Минорная субдоминанта", "Minor", ["i", "iv", "bVII", "i"], 4, .blue),
            progression("aeolian-cinematic", "Кинематографичный минор", "Minor", ["i", "bVI | iv", "V", "i"], 3, .red, usesBorrowedHarmony: true),
            progression("aeolian-dark-pop", "Темная поп-петля", "Minor", ["i", "bVI", "bVII", "i"], 5, .green),
            progression("aeolian-epic", "Эпический минор", "Minor", ["i", "bVII", "bIII", "bVI"], 5, .yellow),
            progression("aeolian-rock", "Минорный рок", "Minor", ["i", "iv", "bVI", "bVII"], 4, .blue),
            progression("aeolian-rise", "Подъем к bVII", "Minor", ["i", "bIII", "bVI", "bVII"], 4, .green)
        ],
        "locrian": [
            progression("locrian-bii", "Опора на bII", "Modal", ["i°", "bII", "i°", "iv"], 3, .red),
            progression("locrian-six", "Через bVI", "Modal", ["i°", "bVI", "bII", "i°"], 2, .yellow),
            progression("locrian-four", "Полууменьшенная петля", "Modal", ["i°", "iv", "bII", "i°"], 2, .blue),
            progression("locrian-release", "С выходом в bVII", "Modal", ["i°", "bvii", "bII", "i°"], 2, .green),
            progression("locrian-tension", "Напряженная bII-iv", "Modal", ["i°", "bII", "iv", "bII"], 3, .red),
            progression("locrian-flat-five", "Центр b5", "Modal", ["i°", "bV", "iv", "bII"], 2, .yellow),
            progression("locrian-ambient", "Атмосферная петля", "Modal", ["i°", "bII", "bVI", "iv"], 2, .blue),
            progression("locrian-return", "Возврат в i°", "Modal", ["i°", "bvii", "iv", "i°"], 2, .green)
        ]
    ]

    private static func progression(
        _ id: String,
        _ title: String,
        _ category: String,
        _ degrees: [String],
        _ popularity: Int,
        _ color: HarmonyColor,
        usesBorrowedHarmony: Bool = false
    ) -> PopularProgression {
        PopularProgression(
            id: id,
            title: title,
            category: category,
            bars: degrees.map { value in
                value
                    .components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            },
            popularity: popularity,
            color: color,
            usesBorrowedHarmony: usesBorrowedHarmony
        )
    }
}
