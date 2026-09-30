import SwiftUI

extension Course: Identifiable {
    var id: String {
        "\(day)|\(row)|\(courseName)|\(timeStart)|\(weekText)"
    }
}

struct CourseCardView: View {
    let course: Course
    var dimmed = false
    var badge: String? = nil
    let onClick: () -> Void

    private var accent: Color {
        Color(Palette.color(for: course))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(course.timeStart)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(accent)
                Text(course.timeEnd)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 66)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(course.courseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accentColor)
                    }
                }
                Text(detailLine)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(dimmed ? 0.16 : 0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(dimmed ? 0.25 : 0.65), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(perform: onClick)
    }

    private var detailLine: String {
        let parts = [course.roomShort.isEmpty ? nil : course.roomShort, course.teacher]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        let joined = parts.joined(separator: " · ")
        return joined.isEmpty ? course.periodLabel : joined
    }
}

struct CourseBlockView: View {
    let course: Course

    private var accent: Color {
        Color(Palette.color(for: course))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(course.courseName)
                .font(.footnote)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .foregroundColor(.primary)
            Text(course.roomShort)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.30))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CourseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(course.courseName)
                .font(.title3)
                .fontWeight(.bold)

            DetailRowView(label: "教师", value: course.teacher)
            DetailRowView(label: "教室", value: course.room)
            DetailRowView(label: "时间", value: timeLine)
            DetailRowView(label: "周次", value: course.weekText.isEmpty ? nil : course.weekText)
            DetailRowView(label: "节次", value: periodLine)

            Spacer()

            Button("关闭") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .presentationDetents([.medium])
    }

    private var timeLine: String? {
        var parts: [String] = []
        if !course.dayName.isEmpty {
            parts.append(course.dayName)
        }
        let time = [course.timeStart, course.timeEnd]
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
        if !time.isEmpty {
            parts.append(time)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private var periodLine: String? {
        guard !course.periods.isEmpty else { return nil }
        return course.periods.map { String(format: "%02d", $0) }.joined(separator: ",")
    }
}

struct DetailRowView: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .leading)
                Text(value)
                    .font(.body)
                Spacer(minLength: 0)
            }
        }
    }
}
