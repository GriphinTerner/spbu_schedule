import Foundation

extension UserDefaults {
    private static let weeksKey = "savedWeeks"
    private static let eventsKey = "savedEvents"

    func saveWeeks(_ weeks: [[Date.Day]]) {
        if let data = try? JSONEncoder().encode(weeks) {
            set(data, forKey: Self.weeksKey)
        }
    }

    func loadWeeks() -> [[Date.Day]] {
        if let data = data(forKey: Self.weeksKey),
           let weeks = try? JSONDecoder().decode([[Date.Day]].self, from: data) {
            return weeks
        }
        return []
    }

    func saveEvents(_ events: [Date: [Event]]) {
        let encoder = JSONEncoder()
        let dict = events.mapKeys { $0.ISO8601String }
        if let data = try? encoder.encode(dict) {
            set(data, forKey: Self.eventsKey)
        }
    }

    func loadEvents() -> [Date: [Event]] {
        if let data = data(forKey: Self.eventsKey),
           let dict = try? JSONDecoder().decode([String: [Event]].self, from: data) {
            return dict.mapKeys { Date.fromISO8601($0) }
        }
        return [:]
    }
}

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: self.map { (transform($0.key), $0.value) })
    }
}

extension Date {
    var ISO8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    static func fromISO8601(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date()
    }
}
