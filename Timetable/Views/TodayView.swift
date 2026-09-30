import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: AppModel
    @State private var detail: Course? = nil

    private let today = Date()

    private var week: Int? {
        Weeks.currentWeek(firstWeekMonday: model.firstWeekMonday, today: today)
    }

    private var courses: [Course] {
        guard let schedule = model.schedule else { return [] }
        let base: [Course]
        if let week = week {
            base = schedule.coursesOfWeek(week)
        } else {
            base = schedule.courses
        }
        let todayIndex = Weeks.todayIndex(today)
        return base.filter { $0.day == todayIndex }
            .sorted { $0.timeStart < $1.timeStart }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                if model.firstWeekMonday == nil {
                    setSchoolPrompt
                }

                Spacer()
                    .frame(height: 14)

                content

                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .refreshable {
            await model.refresh()
        }
        .sheet(item: $detail) { course in
            CourseDetailView(course: course)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: today))
                    .font(.system(size: 28, weight: .bold))
                HStack(spacing: 0) {
                    Text(Weeks.weekdayName(Weeks.todayIndex(today)))
                    if let week = week {
                        Text(" · 第\(week)周")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
            if let schedule = model.schedule {
                Text(week == nil ? "未按周次过滤" : (schedule.weekInfo.term ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var setSchoolPrompt: some View {
        HStack(spacing: 12) {
            Text("尚未设置开学日期，无法计算当前周次")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("去设置") {
                model.goSettings()
            }
            .font(.footnote)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.12))
        )
        .padding(.top, 12)
    }

    @ViewBuilder
    private var content: some View {
        if model.schedule == nil {
            EmptyStateView(text: "暂无课表数据", actionLabel: "重新加载") {
                Task { await model.refresh() }
            }
        } else if courses.isEmpty {
            Text(week == nil ? "今天没有课" : "今天没有课，好好休息")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
        } else {
            let statuses = courses.map { status(of: $0) }
            let nextIndex = statuses.firstIndex(of: .upcoming)
            ForEach(Array(courses.enumerated()), id: \.offset) { index, course in
                let status = statuses[index]
                CourseCardView(
                    course: course,
                    dimmed: status == .past,
                    badge: badge(for: status, isNext: index == nextIndex)
                ) {
                    detail = course
                }
                .padding(.top, 8)
            }
        }
    }

    private func badge(for status: CourseStatus, isNext: Bool) -> String? {
        switch status {
        case .ongoing:
            return "进行中"
        case .upcoming:
            return isNext ? "下一节" : nil
        case .past:
            return nil
        }
    }

    private func status(of course: Course) -> CourseStatus {
        let nowMinutes = Calendar.current.component(.hour, from: Date()) * 60
            + Calendar.current.component(.minute, from: Date())
        guard let start = Self.parseTime(course.timeStart) else { return .upcoming }
        if nowMinutes < start { return .upcoming }
        if let end = Self.parseTime(course.timeEnd), nowMinutes >= end { return .past }
        return .ongoing
    }

    private static func parseTime(_ value: String) -> Int? {
        let parts = value.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()
}

enum CourseStatus {
    case past
    case ongoing
    case upcoming
}

struct EmptyStateView: View {
    let text: String
    let actionLabel: String
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
            Button(actionLabel, action: onAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}
