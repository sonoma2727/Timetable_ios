import Foundation

final class JwxtClient {

    static let base = "http://jwxt.cqrk.edu.cn:18080"
    static let loginURL = "\(base)/jsxsd/xk/LoginToXk"
    static let kbURL = "\(base)/jsxsd/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL"

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        session = URLSession(configuration: config)
    }

    func login(account: String, password: String) async throws {
        let encoded = encodePassword(password)
        let bodyParams: [(String, String)] = [
            ("userAccount", account),
            ("userPassword", ""),
            ("encoded", base64(account) + "%%%" + base64(encoded.password)),
            ("pwdstr1", encoded.pwdstr1),
            ("pwdstr2", encoded.pwdstr2),
        ]
        var request = URLRequest(url: URL(string: Self.loginURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncode(bodyParams)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown("教务系统响应异常")
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        if !(200...299).contains(http.statusCode) {
            throw AppError.login("教务系统返回 HTTP \(http.statusCode)")
        }
        let finalURL = http.url?.absoluteString ?? ""
        if !finalURL.contains("xsMain") || !text.contains("userid") {
            throw AppError.login(extractError(text) ?? "登录失败，请检查学号和密码")
        }
    }

    func fetchScheduleHTML() async throws -> String {
        var request = URLRequest(url: URL(string: Self.kbURL)!)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown("教务系统响应异常")
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        if !(200...299).contains(http.statusCode) {
            throw AppError.http(http.statusCode)
        }
        if !text.contains("kbtable") {
            throw AppError.sessionExpired
        }
        return text
    }

    private func extractError(_ html: String) -> String? {
        if let m = RegexUtil.first(
            #"id=["']showMsg["'][^>]*>(.*?)</li>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators],
            in: html
        ) {
            var msg = RegexUtil.replace(#"<[^>]+>"#, in: m[1], with: "")
            msg = msg.replacingOccurrences(of: "&nbsp;", with: " ")
            msg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
            if !msg.isEmpty { return msg }
        }
        if let m = RegexUtil.first(
            #"alert\(['"]([^'"]+)['"]\)"#,
            in: html
        ) {
            let msg = m[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if !msg.contains("不能为空") { return msg }
        }
        if let m = RegexUtil.first(
            #"<font[^>]*color=["']?red["']?[^>]*>([^<]{2,80})</font>"#,
            options: [.caseInsensitive],
            in: html
        ) {
            let msg = m[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if !msg.contains("温馨提示") && !msg.contains("IE") { return msg }
        }
        return nil
    }

    private func encodePassword(_ password: String) -> (password: String, pwdstr1: String, pwdstr2: String) {
        var chars = Array(password)
        var s1 = ""
        var s2 = ""
        for i in 0..<chars.count {
            switch chars[i] {
            case "\u{3002}":
                chars[i] = "."
                s1 += "\(i),"
            case "\u{ff0c}":
                chars[i] = ","
                s2 += "\(i),"
            default:
                break
            }
        }
        return (String(chars), s1, s2)
    }

    private func base64(_ value: String) -> String {
        Data(value.utf8).base64EncodedString()
    }

    private func formEncode(_ params: [(String, String)]) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* ")
        return params.map { key, value in
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(key)=\(v)"
        }.joined(separator: "&")
    }
}
