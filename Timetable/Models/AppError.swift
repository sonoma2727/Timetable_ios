import Foundation

enum AppError: LocalizedError {
    case login(String)
    case sessionExpired
    case notLoggedIn
    case http(Int)
    case parse(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .login(let message):
            return message
        case .sessionExpired:
            return "登录已过期，请重新登录"
        case .notLoggedIn:
            return "请先登录教务系统"
        case .http(let code):
            return "教务系统返回 HTTP \(code)"
        case .parse(let message):
            return message
        case .unknown(let message):
            return message
        }
    }

    var needsLogin: Bool {
        switch self {
        case .login, .notLoggedIn, .sessionExpired:
            return true
        default:
            return false
        }
    }
}
