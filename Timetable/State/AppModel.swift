import Foundation

@MainActor
final class AppModel: ObservableObject {

    @Published var initialized = false
    @Published var needLogin = false
    @Published var schedule: Schedule? = nil
    @Published var loading = false
    @Published var loginError: String? = nil
    @Published var notice: String? = nil
    @Published var account = ""
    @Published var firstWeekMonday: Date? = nil
    @Published var requestedTab: Int? = nil

    private let client = JwxtClient()
    private let cache = ScheduleCache()
    private let keychain = KeychainStore()
    private let settings = SettingsStore()
    private var refreshInFlight = false
    private var sessionAlive = false

    init() {
        let cached = cache.read()
        let creds = keychain.current()
        let monday = settings.firstWeekMonday
        if let cached = cached {
            Palette.install(courses: cached.courses)
        }
        schedule = cached
        account = creds?.account ?? ""
        firstWeekMonday = monday
        needLogin = creds == nil
        initialized = true
        if creds != nil {
            Task { await refresh(silent: true) }
        }
    }

    func login(account: String, password: String, remember: Bool) {
        loading = true
        loginError = nil
        Task {
            do {
                try await client.login(account: account, password: password)
                sessionAlive = true
            } catch {
                handle(error, fromLogin: true)
                return
            }
            keychain.save(account: account, password: password, remember: remember)
            firstWeekMonday = settings.firstWeekMonday
            needLogin = false
            self.account = remember ? account : ""
            loginError = nil
            loading = false
            await refresh()
        }
    }

    func refresh(silent: Bool = false) async {
        if refreshInFlight { return }
        refreshInFlight = true
        defer { refreshInFlight = false }
        if !silent {
            loading = true
        }
        let fetchTask = Task { try await fetchWithRetry() }
        do {
            let newSchedule = try await fetchTask.value
            Palette.install(courses: newSchedule.courses)
            schedule = newSchedule
            loading = false
            notice = silent ? nil : "课表已更新"
        } catch {
            handle(error, fromLogin: false)
        }
    }

    func refreshIfStale() {
        if needLogin || loading { return }
        let fetchedAt = schedule?.fetchedAt ?? 0
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        if now - fetchedAt >= 600_000 {
            Task { await refresh(silent: true) }
        }
    }

    func logout() {
        let keepMonday = firstWeekMonday
        keychain.clear()
        cache.clear()
        sessionAlive = false
        schedule = nil
        account = ""
        loginError = nil
        notice = nil
        loading = false
        firstWeekMonday = keepMonday
        needLogin = true
    }

    func setFirstWeekMonday(date: Date) {
        let monday = Weeks.mondayOf(date)
        settings.setFirstWeekMonday(monday)
        firstWeekMonday = monday
    }

    func clearNotice() {
        notice = nil
    }

    func goSettings() {
        requestedTab = 2
    }

    private func fetchWithRetry() async throws -> Schedule {
        var lastError: Error = AppError.unknown("刷新失败")
        for attempt in 0..<3 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
            }
            do {
                return try await fetchOnce()
            } catch AppError.sessionExpired {
                sessionAlive = false
                lastError = AppError.sessionExpired
            } catch let error as URLError {
                if error.code == .cancelled { throw error }
                lastError = error
            } catch {
                throw error
            }
        }
        throw lastError
    }

    private func fetchOnce() async throws -> Schedule {
        try await ensureSession()
        let html: String
        do {
            html = try await client.fetchScheduleHTML()
        } catch AppError.sessionExpired {
            sessionAlive = false
            try await ensureSession()
            html = try await client.fetchScheduleHTML()
        }
        let weekInfo = ScheduleParser.extractWeekInfo(html)
        let table = try ScheduleParser.parseTable(html)
        let newSchedule = Schedule(
            source: JwxtClient.base,
            fetchedAt: Int64(Date().timeIntervalSince1970 * 1000),
            weekInfo: weekInfo,
            days: table.days,
            times: table.times,
            courses: table.courses
        )
        cache.write(newSchedule)
        return newSchedule
    }

    private func ensureSession() async throws {
        if sessionAlive { return }
        guard let creds = keychain.current() else {
            throw AppError.notLoggedIn
        }
        client.clearCookies()
        try await client.login(account: creds.account, password: creds.password)
        sessionAlive = true
    }

    private func handle(_ error: Error, fromLogin: Bool) {
        let message: String
        if let appError = error as? AppError {
            switch appError {
            case .unknown(let text):
                message = text
            default:
                message = appError.errorDescription ?? "出错了，请稍后重试"
            }
        } else if let urlError = error as? URLError {
            if urlError.code == .cancelled {
                loading = false
                return
            }
            message = "网络异常，请检查网络连接（\(urlError.code.rawValue)）"
        } else {
            message = error.localizedDescription
        }

        if fromLogin {
            loginError = message
            notice = nil
        } else {
            notice = message
            if let appError = error as? AppError, appError.needsLogin, schedule == nil {
                needLogin = true
            }
        }
        loading = false
    }
}
