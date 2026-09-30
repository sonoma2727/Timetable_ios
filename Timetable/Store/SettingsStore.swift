import Foundation

final class SettingsStore {

    private let key = "first_week_monday"

    var firstWeekMonday: Date? {
        guard let ts = UserDefaults.standard.object(forKey: key) as? Double else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    func setFirstWeekMonday(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
    }
}
