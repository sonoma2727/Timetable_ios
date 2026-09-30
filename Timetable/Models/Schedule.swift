import Foundation

struct TimeSlot: Codable, Equatable {
    var label: String = ""
    var time: String = ""
}

struct Course: Codable, Equatable {
    var courseName: String
    var teacher: String? = nil
    var room: String? = nil
    var day: Int = 1
    var row: Int = 0
    var spanRows: Int = 1
    var periods: [Int] = []
    var timeStart: String = ""
    var timeEnd: String = ""
    var periodLabel: String = ""
    var dayName: String = ""
    var weekText: String = ""
    var weeks: [Int] = []

    func inWeek(_ week: Int) -> Bool {
        weeks.isEmpty || weeks.contains(week)
    }

    enum CodingKeys: String, CodingKey {
        case courseName, teacher, room, day, row, spanRows, periods
        case timeStart, timeEnd, periodLabel, dayName, weekText, weeks
    }

    init(
        courseName: String,
        teacher: String? = nil,
        room: String? = nil,
        day: Int = 1,
        row: Int = 0,
        spanRows: Int = 1,
        periods: [Int] = [],
        timeStart: String = "",
        timeEnd: String = "",
        periodLabel: String = "",
        dayName: String = "",
        weekText: String = "",
        weeks: [Int] = []
    ) {
        self.courseName = courseName
        self.teacher = teacher
        self.room = room
        self.day = day
        self.row = row
        self.spanRows = spanRows
        self.periods = periods
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.periodLabel = periodLabel
        self.dayName = dayName
        self.weekText = weekText
        self.weeks = weeks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        courseName = try c.decode(String.self, forKey: .courseName)
        teacher = try c.decodeIfPresent(String.self, forKey: .teacher)
        room = try c.decodeIfPresent(String.self, forKey: .room)
        day = try c.decodeIfPresent(Int.self, forKey: .day) ?? 1
        row = try c.decodeIfPresent(Int.self, forKey: .row) ?? 0
        spanRows = try c.decodeIfPresent(Int.self, forKey: .spanRows) ?? 1
        periods = try c.decodeIfPresent([Int].self, forKey: .periods) ?? []
        timeStart = try c.decodeIfPresent(String.self, forKey: .timeStart) ?? ""
        timeEnd = try c.decodeIfPresent(String.self, forKey: .timeEnd) ?? ""
        periodLabel = try c.decodeIfPresent(String.self, forKey: .periodLabel) ?? ""
        dayName = try c.decodeIfPresent(String.self, forKey: .dayName) ?? ""
        weekText = try c.decodeIfPresent(String.self, forKey: .weekText) ?? ""
        weeks = try c.decodeIfPresent([Int].self, forKey: .weeks) ?? []
    }
}

struct WeekInfo: Codable, Equatable {
    var term: String? = nil
    var timeTemplate: String? = nil
    var weeks: [Int] = []

    enum CodingKeys: String, CodingKey {
        case term, timeTemplate, weeks
    }

    init(term: String? = nil, timeTemplate: String? = nil, weeks: [Int] = []) {
        self.term = term
        self.timeTemplate = timeTemplate
        self.weeks = weeks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        term = try c.decodeIfPresent(String.self, forKey: .term)
        timeTemplate = try c.decodeIfPresent(String.self, forKey: .timeTemplate)
        weeks = try c.decodeIfPresent([Int].self, forKey: .weeks) ?? []
    }
}

struct Schedule: Codable, Equatable {
    var source: String = ""
    var fetchedAt: Int64 = 0
    var weekInfo: WeekInfo = WeekInfo()
    var days: [String] = []
    var times: [TimeSlot] = []
    var courses: [Course] = []

    func coursesOfWeek(_ week: Int) -> [Course] {
        courses.filter { $0.inWeek(week) }
    }

    enum CodingKeys: String, CodingKey {
        case source, fetchedAt, weekInfo, days, times, courses
    }

    init(
        source: String = "",
        fetchedAt: Int64 = 0,
        weekInfo: WeekInfo = WeekInfo(),
        days: [String] = [],
        times: [TimeSlot] = [],
        courses: [Course] = []
    ) {
        self.source = source
        self.fetchedAt = fetchedAt
        self.weekInfo = weekInfo
        self.days = days
        self.times = times
        self.courses = courses
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? ""
        fetchedAt = try c.decodeIfPresent(Int64.self, forKey: .fetchedAt) ?? 0
        weekInfo = try c.decodeIfPresent(WeekInfo.self, forKey: .weekInfo) ?? WeekInfo()
        days = try c.decodeIfPresent([String].self, forKey: .days) ?? []
        times = try c.decodeIfPresent([TimeSlot].self, forKey: .times) ?? []
        courses = try c.decodeIfPresent([Course].self, forKey: .courses) ?? []
    }
}
