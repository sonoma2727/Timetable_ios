import UIKit

enum Palette {

    private static let coursePaletteSize = 20

    private static func slotRgb(_ index: Int) -> (Double, Double, Double) {
        let hue = (Double(index) * 137.508).truncatingRemainder(dividingBy: 360.0)
        let sat = 0.50 + 0.10 * ((Double(index) * 0.6180339887 + 0.66).truncatingRemainder(dividingBy: 1.0))
        let lig = 0.37 + 0.26 * ((Double(index) * 0.4142135623).truncatingRemainder(dividingBy: 1.0))
        let c = (1 - abs(2 * lig - 1)) * sat
        let hp = hue / 60.0
        let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
        var r = 0.0
        var g = 0.0
        var b = 0.0
        switch Int(hp) {
        case 0: r = c; g = x
        case 1: r = x; g = c
        case 2: g = c; b = x
        case 3: g = x; b = c
        case 4: r = x; b = c
        default: r = c; b = x
        }
        let m = lig - c / 2
        return ((r + m) * 255, (g + m) * 255, (b + m) * 255)
    }

    private static let slotColors: [(Double, Double, Double)] = (0..<coursePaletteSize).map(slotRgb)

    private static let coursePalette: [UIColor] = slotColors.map {
        UIColor(red: $0.0 / 255.0, green: $0.1 / 255.0, blue: $0.2 / 255.0, alpha: 1.0)
    }

    private static func rgbDist2(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
        let dr = a.0 - b.0
        let dg = a.1 - b.1
        let db = a.2 - b.2
        return dr * dr + dg * dg + db * db
    }

    private static let groupSuffixRegex = try! NSRegularExpression(pattern: #"\s*[（(]分组[^）)]*[）)]"#)

    private static var colorIndexByName: [String: Int] = [:]

    static func normalizedKey(_ name: String) -> String {
        let range = NSRange(name.startIndex..., in: name)
        let stripped = groupSuffixRegex.stringByReplacingMatches(
            in: name, options: [], range: range, withTemplate: ""
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func install(courses: [Course]) {
        let keys = Set(courses.map { normalizedKey($0.courseName) }.filter { !$0.isEmpty }).sorted()
        colorIndexByName.removeAll()
        var used = Set<Int>()
        for key in keys {
            var best = 0
            var bestScore = -Double.greatestFiniteMagnitude
            for i in 0..<coursePaletteSize where !used.contains(i) {
                var minD = Double.greatestFiniteMagnitude
                for u in used {
                    minD = min(minD, rgbDist2(slotColors[i], slotColors[u]))
                }
                if minD > bestScore {
                    bestScore = minD
                    best = i
                }
            }
            colorIndexByName[key] = best
            used.insert(best)
            if used.count == coursePaletteSize { used.removeAll() }
        }
    }

    static func color(for course: Course) -> UIColor {
        let key = normalizedKey(course.courseName)
        if let index = colorIndexByName[key] {
            return coursePalette[index]
        }
        var hash = 0
        for scalar in course.courseName.unicodeScalars {
            hash = hash &* 31 &+ Int(scalar.value)
        }
        let index = Int(hash.magnitude % UInt(coursePaletteSize))
        return coursePalette[index]
    }
}
