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
            progression("ionian-secondary", "V/vi в обороте", "Intermediate", ["I", "V/vi", "vi", "IV", "V"], 3, .red),
            progression("ionian-borrowed-vii", "Каденция через bVII", "Advanced", ["I", "bVII", "IV", "I"], 3, .yellow),
            progression("ionian-royal-road", "Royal road", "Intermediate", ["IV", "V", "iii", "vi"], 5, .green),
            progression("ionian-jazz-turnaround", "Turnaround", "Intermediate", ["I | vi", "ii | V", "I", "V"], 5, .blue),
            progression("ionian-plagal", "Плагальный круг", "Beginner", ["I", "IV", "I", "V"], 4, .green),
            progression("ionian-gospel", "Госпел-оборот", "Advanced", ["I", "III", "IV", "iv"], 3, .yellow)
        ],
        "dorian": [
            progression("dorian-vamp", "Дорийский вамп", "Modal", ["i", "IV", "i", "IV"], 5, .green),
            progression("dorian-backdoor", "i - VII - IV", "Modal", ["i", "VII", "IV", "i"], 4, .blue),
            progression("dorian-two-four", "Минорная опора II-IV", "Modal", ["i", "ii", "IV", "i"], 3, .yellow),
            progression("dorian-five-minor", "С мягкой доминантой", "Modal", ["i", "v", "IV", "i"], 3, .red),
            progression("dorian-bright-minor", "Светлый минор", "Modal", ["i", "IV", "VII", "i"], 5, .green),
            progression("dorian-loop", "Петля i-ii-IV", "Modal", ["i", "ii", "IV", "VII"], 4, .yellow),
            progression("dorian-six-color", "Краска натуральной 6", "Modal", ["i", "IV", "ii", "i"], 4, .blue),
            progression("dorian-open", "Открытый модальный ход", "Modal", ["i", "VII", "ii", "IV"], 3, .green)
        ],
        "phrygian": [
            progression("phrygian-half-step", "Фригийский полутон", "Modal", ["i", "II", "i", "VII"], 5, .red),
            progression("phrygian-spanish", "Испанский оборот", "Modal", ["i", "VII", "VI", "V"], 4, .yellow),
            progression("phrygian-bii", "bII как центр тяжести", "Modal", ["i", "II", "VII", "i"], 4, .green),
            progression("phrygian-dark", "Темная каденция", "Modal", ["i", "iv", "II", "i"], 3, .blue),
            progression("phrygian-rock", "Тяжелый рифф", "Modal", ["i", "II", "III", "II"], 5, .red),
            progression("phrygian-flat-six", "Через bVI", "Modal", ["i", "VI", "II", "i"], 4, .yellow),
            progression("phrygian-bounce", "II-VII петля", "Modal", ["i", "II", "VII", "II"], 4, .green),
            progression("phrygian-minor-four", "Минорная iv", "Modal", ["i", "iv", "VII", "II"], 3, .blue)
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
            progression("mixolydian-rock", "Рок-каденция bVII-IV", "Modal", ["I", "VII", "IV", "I"], 5, .green),
            progression("mixolydian-v-minor", "Минорная v", "Modal", ["I", "v", "VII", "IV"], 4, .blue),
            progression("mixolydian-plagal", "Плагальная петля", "Modal", ["I", "IV", "VII", "I"], 4, .yellow),
            progression("mixolydian-cadence", "Возврат через bVII", "Modal", ["I", "VII", "I", "V"], 3, .red),
            progression("mixolydian-blues-rock", "Блюз-рок", "Modal", ["I", "IV", "I", "VII"], 5, .green),
            progression("mixolydian-country", "Кантри-оборот", "Modal", ["I", "VII", "IV", "V"], 4, .yellow),
            progression("mixolydian-vamp", "I-bVII вамп", "Modal", ["I", "VII", "I", "VII"], 5, .blue),
            progression("mixolydian-soft", "Мягкий миксолидийский", "Modal", ["I", "v", "IV", "I"], 4, .green)
        ],
        "aeolian": [
            progression("aeolian-pop-minor", "Минорная поп-ось", "Minor", ["i", "VI", "III", "VII"], 5, .green),
            progression("aeolian-falling", "Нисходящая цепочка", "Minor", ["i", "VII", "VI", "VII"], 5, .yellow),
            progression("aeolian-subdominant", "Минорная субдоминанта", "Minor", ["i", "iv", "VII", "i"], 4, .blue),
            progression("aeolian-cinematic", "Кинематографичный минор", "Minor", ["i", "VI | iv", "V", "i"], 3, .red),
            progression("aeolian-dark-pop", "Темная поп-петля", "Minor", ["i", "VI", "VII", "i"], 5, .green),
            progression("aeolian-epic", "Эпический минор", "Minor", ["i", "VII", "III", "VI"], 5, .yellow),
            progression("aeolian-rock", "Минорный рок", "Minor", ["i", "iv", "VI", "VII"], 4, .blue),
            progression("aeolian-rise", "Подъем к VII", "Minor", ["i", "III", "VI", "VII"], 4, .green)
        ],
        "locrian": [
            progression("locrian-bii", "Опора на bII", "Modal", ["i°", "II", "i°", "iv"], 3, .red),
            progression("locrian-six", "Через bVI", "Modal", ["i°", "VI", "II", "i°"], 2, .yellow),
            progression("locrian-four", "Полууменьшенная петля", "Modal", ["i°", "iv", "II", "i°"], 2, .blue),
            progression("locrian-release", "С выходом в bVII", "Modal", ["i°", "VII", "II", "i°"], 2, .green),
            progression("locrian-tension", "Напряженная bII-IV", "Modal", ["i°", "II", "iv", "II"], 3, .red),
            progression("locrian-flat-five", "Центр b5", "Modal", ["i°", "VI", "iv", "II"], 2, .yellow),
            progression("locrian-ambient", "Атмосферная петля", "Modal", ["i°", "II", "VI", "iv"], 2, .blue),
            progression("locrian-return", "Возврат в i°", "Modal", ["i°", "VII", "iv", "i°"], 2, .green)
        ]
    ]

    private static func progression(
        _ id: String,
        _ title: String,
        _ category: String,
        _ degrees: [String],
        _ popularity: Int,
        _ color: HarmonyColor
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
            color: color
        )
    }
}
