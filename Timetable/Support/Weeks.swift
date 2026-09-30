import Foundation

enum Weeks {

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func mondayOf(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? startOfDay(date)
    }

    static func currentWeek(firstWeekMonday: Date?, today: Date = Date()) -> Int? {
        guard let firstWeekMonday = firstWeekMonday else { return nil }
        let comps = Calendar.current.dateComponents(
            [.day],
            from: startOfDay(firstWeekMonday),
            to: startOfDay(today)
        )
        let diff = comps.day ?? 0
        return max(diff / 7 + 1, 1)
    }

    static func todayIndex(_ date: Date = Date()) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    static func weekdayName(_ index: Int) -> String {
        let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        guard index >= 1 && index < names.count else { return "" }
        return names[index]
    }
}
