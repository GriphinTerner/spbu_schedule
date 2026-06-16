import SwiftUI

extension Date {
    static func week(for offset: Int) -> [Day] {
        let calendar = Calendar.current
        guard let firstWeekDay = calendar.dateInterval(of: .weekOfMonth, for: .now)?.start else {
            return []
        }

        guard let startOfTargetWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: firstWeekDay) else {
            return []
        }

        var week: [Day] = []
        for index in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: index, to: startOfTargetWeek) {
                week.append(.init(date: day))
            }
        }
        return week
    }

    func string(_ template: String, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
//        formatter.locale = locale
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: self)
    }
    
    func isSame(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    struct Day: Identifiable, Codable, Hashable {
        let id: UUID
        let date: Date

        init(date: Date) {
            self.id = UUID()
            self.date = date
        }

        func isSame(_ other: Date) -> Bool {
            Calendar.current.isDate(self.date, inSameDayAs: other)
        }
    }
}
