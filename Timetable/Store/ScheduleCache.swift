import Foundation

final class ScheduleCache {

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedule.json")
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private let decoder = JSONDecoder()

    func read() -> Schedule? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(Schedule.self, from: data)
    }

    func write(_ schedule: Schedule) {
        guard let data = try? encoder.encode(schedule) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
