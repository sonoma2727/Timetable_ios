import Foundation

enum ScheduleParser {

    struct ParsedTable {
        let days: [String]
        let times: [TimeSlot]
        let courses: [Course]
    }

    private static let dotAll: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
    private static let fontPattern = #"<font[^>]*title=['"]([^'"]*)['"][^>]*>(.*?)</font>"#

    static func stripTags(_ value: String) -> String {
        var s = RegexUtil.replace(#"<br\s*/?>"#, options: [.caseInsensitive], in: value, with: "\n")
        s = RegexUtil.replace(#"<[^>]+>"#, in: s, with: "")
        s = s.replacingOccurrences(of: "&nbsp;", with: " ")
        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&lt;", with: "<")
        s = s.replacingOccurrences(of: "&gt;", with: ">")
        s = s.replacingOccurrences(of: "&quot;", with: "\"")
        s = RegexUtil.replace(#"[ \t]+"#, in: s, with: " ")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func extractWeekInfo(_ html: String) -> WeekInfo {
        var term: String? = nil
        var template: String? = nil
        var weeks: [Int] = []
        for name in ["xnxq01id", "zc", "kbjcmsid"] {
            guard let select = RegexUtil.first(
                #"<select[^>]*name=["']\#(name)["'][^>]*>(.*?)</select>"#,
                options: dotAll,
                in: html
            ) else { continue }
            let opts = RegexUtil.matches(
                #"<option[^>]*value=["']([^"']*)["']([^>]*)>(.*?)</option>"#,
                options: dotAll,
                in: select[1]
            )
            if name == "zc" {
                weeks = opts.compactMap { Int($0[1]) }
            } else {
                for opt in opts where opt[2].contains("selected") {
                    let text = stripTags(opt[3])
                    if name == "xnxq01id" {
                        term = text
                    } else {
                        template = text
                    }
                }
            }
        }
        if weeks.isEmpty {
            var found = Set<Int>()
            for m in RegexUtil.matches(#"[?&]zc=(\d+)"#, in: html) {
                if let v = Int(m[1]) { found.insert(v) }
            }
            weeks = found.sorted()
        }
        return WeekInfo(term: term, timeTemplate: template, weeks: weeks)
    }

    static func parseTable(_ html: String) throws -> ParsedTable {
        guard let table = RegexUtil.first(
            #"<table[^>]*id=["']kbtable["'][^>]*>(.*?)</table>"#,
            options: dotAll,
            in: html
        )?[1] else {
            throw AppError.parse("kbtable not found")
        }
        let trs = RegexUtil.matches(#"<tr[^>]*>(.*?)</tr>"#, options: dotAll, in: table).map { $0[1] }
        if trs.isEmpty { throw AppError.parse("empty kbtable") }

        var days = RegexUtil.matches(#"<th[^>]*>(.*?)</th>"#, options: dotAll, in: trs[0])
            .map { stripTags($0[1]) }
        if !days.isEmpty { days.removeFirst() }

        var rowsRaw: [[(head: String, body: String)]] = []
        var times: [TimeSlot] = []
        for i in 1..<trs.count {
            let cells = RegexUtil.matches(
                #"(<t[dh][^>]*>)(.*?)</t[dh]>"#,
                options: dotAll,
                in: trs[i]
            ).map { (head: $0[1], body: $0[2]) }
            if cells.isEmpty { continue }
            let headerText = stripTags(cells[0].body)
            let timeMatch = RegexUtil.first(#"(\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2})"#, in: headerText)
            let timeRange = timeMatch.map { $0[1].replacingOccurrences(of: " ", with: "") } ?? ""
            let label: String
            if let tm = timeMatch {
                label = headerText
                    .replacingOccurrences(of: tm[1], with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                label = headerText
            }
            times.append(TimeSlot(label: label, time: timeRange))
            rowsRaw.append(Array(cells.dropFirst()))
        }

        var rowFirst: [Int: Int] = [:]
        var periodToRow: [Int: Int] = [:]
        var nextPeriod = 1
        for (r, slot) in times.enumerated() {
            let t = slot.time as NSString
            let dash = t.range(of: "-").location
            if dash == NSNotFound || dash <= 0 { continue }
            let a = t.substring(with: NSRange(location: 0, length: dash))
            let b = t.substring(from: dash + 1)
            if a.count < 5 || b.count < 5 { continue }
            guard let ah = Int(a.prefix(2)), let am = Int(a.dropFirst(3).prefix(2)),
                  let bh = Int(b.prefix(2)), let bm = Int(b.dropFirst(3).prefix(2)) else { continue }
            let startMin = ah * 60 + am
            let endMin = bh * 60 + bm
            let dur = endMin - startMin
            let n = max((dur + 5) / 50, 1)
            rowFirst[r] = nextPeriod
            for i in 0..<n { periodToRow[nextPeriod + i] = r }
            nextPeriod += n
        }

        func periodBounds(_ period: Int) -> (Int, Int)? {
            guard let r = periodToRow[period] else { return nil }
            let time = times[r].time as NSString
            let dash = time.range(of: "-").location
            if dash == NSNotFound || dash <= 0 { return nil }
            let a = time.substring(with: NSRange(location: 0, length: dash))
            if a.count < 5 { return nil }
            guard let h = Int(a.prefix(2)), let m = Int(a.dropFirst(3).prefix(2)) else { return nil }
            let base = h * 60 + m + (period - (rowFirst[r] ?? 1)) * 50
            return (base, base + 45)
        }

        func hhmm(_ minutes: Int) -> String {
            String(format: "%02d:%02d", minutes / 60, minutes % 60)
        }

        var schedule: [Course] = []
        var seen = Set<String>()
        for (r, cells) in rowsRaw.enumerated() {
            if r < times.count && times[r].label.contains("备注") { continue }
            for (c, cell) in cells.enumerated() {
                let content = cell.body
                if c >= days.count || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                for raw in parseCell(content) {
                    var course = raw
                    var periods = raw.periods
                    if periods.isEmpty {
                        let first = rowFirst[r] ?? 1
                        periods = (first..<(first + 1)).filter { periodToRow[$0] == r }
                        if periods.isEmpty { periods = [1] }
                    }
                    let rows = periods.compactMap { periodToRow[$0] }.sorted()
                    let startRow = rows.first ?? r
                    let endRow = rows.last ?? r
                    let starts = periods.compactMap { periodBounds($0)?.0 }
                    let ends = periods.compactMap { periodBounds($0)?.1 }
                    course.day = c + 1
                    course.dayName = c < days.count ? days[c] : "\(c + 1)"
                    course.row = startRow
                    course.spanRows = endRow - startRow + 1
                    course.periodLabel = startRow < times.count ? times[startRow].label : ""
                    course.periods = periods
                    course.timeStart = starts.min().map(hhmm) ?? ""
                    course.timeEnd = ends.max().map(hhmm) ?? ""
                    let key = [
                        "\(course.day)",
                        course.courseName,
                        course.teacher ?? "",
                        course.room ?? "",
                        course.weekText,
                        course.periods.map(String.init).joined(separator: ","),
                    ].joined(separator: "\u{1}")
                    if seen.insert(key).inserted {
                        schedule.append(course)
                    }
                }
            }
        }

        let indexed = schedule.enumerated().map { (offset: $0.offset, course: $0.element) }
        let sorted = indexed.sorted { a, b in
            if a.course.day != b.course.day { return a.course.day < b.course.day }
            if a.course.row != b.course.row { return a.course.row < b.course.row }
            let pa = a.course.periods.first ?? 0
            let pb = b.course.periods.first ?? 0
            if pa != pb { return pa < pb }
            return a.offset < b.offset
        }
        schedule = sorted.map { $0.course }

        let visibleTimes = times.filter { !$0.time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let validCourses = schedule.filter { $0.row < visibleTimes.count }
        return ParsedTable(days: days, times: visibleTimes, courses: validCourses)
    }

    static func parseCell(_ tdHtml: String) -> [Course] {
        var divs = RegexUtil.matches(
            #"<div[^>]*class=["']kbcontent["'][^>]*>(.*?)</div>"#,
            options: dotAll,
            in: tdHtml
        ).map { $0[1] }
        if divs.isEmpty {
            divs = RegexUtil.matches(
                #"<div[^>]*class=["']kbcontent1["'][^>]*>(.*?)</div>"#,
                options: dotAll,
                in: tdHtml
            ).map { $0[1] }
        }
        var courses: [Course] = []
        for div in divs {
            if div.contains("&nbsp;") && !RegexUtil.contains(fontPattern, options: dotAll, in: div) {
                continue
            }
            for part in RegexUtil.split(#"-{5,}"#, in: div) {
                guard let course = parseBlock(part) else { continue }
                if !course.courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !course.weekText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    courses.append(course)
                }
            }
        }
        return courses
    }

    static func parseBlock(_ blockHtml: String) -> Course? {
        var fonts: [String: String] = [:]
        for m in RegexUtil.matches(fontPattern, options: dotAll, in: blockHtml) {
            fonts[m[1]] = stripTags(m[2])
        }
        let firstPart = RegexUtil.split(fontPattern, options: dotAll, in: blockHtml)[0]
        var name = stripTags(firstPart)
        name = RegexUtil.split(#"\s+"#, in: name).joined(separator: " ")
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.trimmingCharacters(in: CharacterSet(charactersIn: "- "))
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty && fonts.isEmpty { return nil }

        var course = Course(courseName: name)
        course.teacher = fonts["老师"] ?? fonts["教师"]
        course.room = fonts["教室"]
        let weekVal = fonts.first { $0.key.hasPrefix("周次") }?.value
        if let weekVal = weekVal {
            course.weekText = weekVal
            let parsed = parseWeeks(weekVal)
            course.weeks = parsed.weeks
            course.periods = parsed.periods
        }
        return course
    }

    static func parseWeeks(_ value: String) -> (weeks: [Int], periods: [Int]) {
        var weekSet = Set<Int>()
        let weekValRegex = #"([\d,\s、，\-]+)\(([周单双])\)"#
        for m in RegexUtil.matches(weekValRegex, in: value) {
            let kind = m[2]
            let body = m[1]
                .replacingOccurrences(of: "，", with: ",")
                .replacingOccurrences(of: "、", with: ",")
                .replacingOccurrences(of: " ", with: "")
            for part in body.components(separatedBy: ",") where !part.isEmpty {
                let ns = part as NSString
                let dash = ns.range(of: "-").location
                var range: ClosedRange<Int>? = nil
                if dash != NSNotFound && dash > 0 {
                    guard let lo = Int(ns.substring(to: dash)),
                          let hi = Int(ns.substring(from: dash + 1)) else { continue }
                    range = lo...max(lo, hi)
                } else if let v = Int(part) {
                    range = v...v
                } else {
                    continue
                }
                guard let range = range else { continue }
                for w in range {
                    if kind == "单" && w % 2 == 0 { continue }
                    if kind == "双" && w % 2 == 1 { continue }
                    weekSet.insert(w)
                }
            }
        }
        var periods: [Int] = []
        let bracket = (value as NSString).range(of: "[").location
        if bracket != NSNotFound {
            let tail = (value as NSString).substring(from: bracket)
            var set = Set<Int>()
            for m in RegexUtil.matches(#"\d{1,2}"#, in: tail) {
                if let v = Int(m[0]) { set.insert(v) }
            }
            periods = set.sorted()
        }
        return (weekSet.sorted(), periods)
    }
}
