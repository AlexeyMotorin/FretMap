import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.fretmap.app"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let orientation = Logger(subsystem: subsystem, category: "orientation")
}
