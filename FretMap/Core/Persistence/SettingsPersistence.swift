import Foundation

protocol SettingsPersisting {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
}

struct UserDefaultsSettingsPersistence: SettingsPersisting {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func set(_ data: Data, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}

final class InMemorySettingsPersistence: SettingsPersisting {
    private var storage: [String: Data] = [:]
    private(set) var writeCount = 0

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ data: Data, forKey key: String) {
        writeCount += 1
        storage[key] = data
    }
}
