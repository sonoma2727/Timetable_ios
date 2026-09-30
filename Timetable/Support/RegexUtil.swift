import Foundation

enum RegexUtil {

    static func matches(
        _ pattern: String,
        options: NSRegularExpression.Options = [],
        in text: String
    ) -> [[String]] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        return re.matches(in: text, range: range).map { m in
            (0..<m.numberOfRanges).map { i -> String in
                let r = m.range(at: i)
                return r.location == NSNotFound ? "" : ns.substring(with: r)
            }
        }
    }

    static func first(
        _ pattern: String,
        options: NSRegularExpression.Options = [],
        in text: String
    ) -> [String]? {
        matches(pattern, options: options, in: text).first
    }

    static func contains(_ pattern: String, options: NSRegularExpression.Options = [], in text: String) -> Bool {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return re.firstMatch(in: text, range: range) != nil
    }

    static func replace(
        _ pattern: String,
        options: NSRegularExpression.Options = [],
        in text: String,
        with template: String
    ) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return re.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }

    static func split(_ pattern: String, options: NSRegularExpression.Options = [], in text: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else {
            return [text]
        }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        var parts: [String] = []
        var last = 0
        for m in re.matches(in: text, range: full) {
            parts.append(ns.substring(with: NSRange(location: last, length: m.range.location - last)))
            last = m.range.location + m.range.length
        }
        parts.append(ns.substring(with: NSRange(location: last, length: ns.length - last)))
        return parts
    }
}
