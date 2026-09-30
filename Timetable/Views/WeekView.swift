import SwiftUI
import UIKit

struct WeekView: View {
    @EnvironmentObject private var model: AppModel
    @State private var detail: Course? = nil
    @State private var weekIndex: Int? = nil

    private var schedule: Schedule? { model.schedule }

    private var weeks: [Int] {
        guard let schedule = schedule else { return [] }
        return schedule.weekInfo.weeks.isEmpty ? Array(1...18) : schedule.weekInfo.weeks
    }

    private var currentWeek: Int? {
        Weeks.currentWeek(firstWeekMonday: model.firstWeekMonday)
    }

    private var selection: Binding<Int> {
        Binding(
            get: {
                if let weekIndex = weekIndex, weeks.contains(weekIndex) {
                    return weeks.firstIndex(of: weekIndex) ?? 0
                }
                if let currentWeek = currentWeek, let i = weeks.firstIndex(of: currentWeek) {
                    return i
                }
                return 0
            },
            set: { weekIndex = weeks[$0] }
        )
    }

    private var selectedWeek: Int {
        weeks[selection.wrappedValue]
    }

    var body: some View {
        Group {
            if let schedule = schedule {
                VStack(spacing: 0) {
                    header
                    if currentWeek == nil {
                        Button("未设置开学日期，点击设置以定位本周") {
                            model.goSettings()
                        }
                        .font(.footnote)
                        .padding(.leading, 8)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    pager(schedule: schedule)
                }
            } else {
                EmptyStateView(text: "暂无课表数据", actionLabel: "重新加载") {
                    Task { await model.refresh() }
                }
            }
        }
        .refreshable {
            await model.refresh()
        }
        .sheet(item: $detail) { course in
            CourseDetailView(course: course)
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Button {
                step(-1)
            } label: {
                Text("◀")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .disabled(selection.wrappedValue <= 0)

            Menu {
                ForEach(weeks, id: \.self) { week in
                    Button("第\(week)周") {
                        weekIndex = week
                    }
                }
            } label: {
                Text("第\(selectedWeek)周")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }

            Button {
                step(1)
            } label: {
                Text("▶")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .disabled(selection.wrappedValue >= weeks.count - 1)

            Spacer()

            if let currentWeek = currentWeek,
               weeks.contains(currentWeek),
               selectedWeek != currentWeek {
                Button("本周") {
                    weekIndex = currentWeek
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func step(_ delta: Int) {
        let target = selection.wrappedValue + delta
        if target >= 0 && target < weeks.count {
            weekIndex = weeks[target]
        }
    }

    private func pager(schedule: Schedule) -> some View {
        TabView(selection: selection) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                WeekGridView(
                    schedule: schedule,
                    week: week,
                    currentWeek: currentWeek,
                    onCourseClick: { detail = $0 }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct WeekGridView: View {
    let schedule: Schedule
    let week: Int
    let currentWeek: Int?
    let onCourseClick: (Course) -> Void

    private let timeColWidth: CGFloat = 46
    private let minRowHeight: CGFloat = 84

    private var todayIndex: Int {
        Weeks.todayIndex()
    }

    private var isCurrentWeek: Bool {
        currentWeek != nil && week == currentWeek
    }

    var body: some View {
        let days = schedule.days
        let times = schedule.times

        if times.isEmpty || days.isEmpty {
            Text("暂无课节时间数据")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let courses = schedule.coursesOfWeek(week).filter {
                $0.day >= 1 && $0.day <= days.count && $0.row >= 0 && $0.row < times.count
            }

            VStack(spacing: 0) {
                dayHeader(days: days)
                GeometryReader { geo in
                    let cellW = (geo.size.width - timeColWidth) / CGFloat(days.count)
                    let rowH = max(geo.size.height / CGFloat(times.count), minRowHeight)
                    ScrollView(.vertical, showsIndicators: false) {
                        gridContent(
                            days: days,
                            times: times,
                            courses: courses,
                            totalWidth: geo.size.width,
                            cellW: cellW,
                            rowH: rowH
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private func dayHeader(days: [String]) -> some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: timeColWidth)
            ForEach(Array(days.enumerated()), id: \.offset) { index, name in
                let highlight = isCurrentWeek && (index + 1) == todayIndex
                Text(name.replacingOccurrences(of: "星期", with: "周"))
                    .font(.footnote)
                    .fontWeight(highlight ? .bold : .regular)
                    .foregroundColor(highlight ? Color.accentColor : .secondary)
                    .padding(.horizontal, highlight ? 6 : 0)
                    .padding(.vertical, 1)
                    .background(
                        Group {
                            if highlight {
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.14))
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 8)
    }

    private func gridContent(
        days: [String],
        times: [TimeSlot],
        courses: [Course],
        totalWidth: CGFloat,
        cellW: CGFloat,
        rowH: CGFloat
    ) -> some View {
        let contentWidth = totalWidth
        let contentHeight = rowH * CGFloat(times.count)
        let gridColor = Color(UIColor.systemGray5)

        return ZStack(alignment: .topLeading) {
            Canvas { context, size in
                let stroke: CGFloat = 1
                for r in 0...times.count {
                    var path = Path()
                    let y = rowH * CGFloat(r)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(gridColor), lineWidth: stroke)
                }
                for c in 0...days.count {
                    var path = Path()
                    let x = timeColWidth + cellW * CGFloat(c)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: rowH * CGFloat(times.count)))
                    context.stroke(path, with: .color(gridColor), lineWidth: stroke)
                }
            }
            .frame(width: contentWidth, height: contentHeight)

            ForEach(Array(times.enumerated()), id: \.offset) { index, slot in
                VStack(spacing: 1) {
                    Text(slot.label)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(slot.time.replacingOccurrences(of: "-", with: "\n"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: timeColWidth - 8)
                .position(
                    x: timeColWidth / 2,
                    y: rowH * (CGFloat(index) + 0.5)
                )
            }

            courseBlocks(
                courses: courses,
                cellW: cellW,
                rowH: rowH,
                timesCount: times.count
            )
        }
        .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private func courseBlocks(
        courses: [Course],
        cellW: CGFloat,
        rowH: CGFloat,
        timesCount: Int
    ) -> some View {
        let groups = Dictionary(grouping: courses, by: { "\($0.row):\($0.day)" })
        ForEach(groups.keys.sorted(), id: \.self) { key in
            let list = groups[key] ?? []
            ForEach(Array(list.enumerated()), id: \.offset) { index, course in
                let fraction = CGFloat(index) / CGFloat(list.count)
                let width = cellW / CGFloat(list.count)
                let span = min(max(course.spanRows, 1), timesCount - course.row)
                let x = timeColWidth + cellW * (CGFloat(course.day - 1) + fraction) + width / 2
                let y = rowH * (CGFloat(course.row) + CGFloat(span) / 2)

                CourseBlockView(course: course)
                    .frame(width: max(width - 4, 24), height: rowH * CGFloat(span) - 4)
                    .position(x: x, y: y)
                    .onTapGesture {
                        onCourseClick(course)
                    }
            }
        }
    }
}
