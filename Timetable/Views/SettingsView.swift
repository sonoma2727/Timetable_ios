import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showDatePicker = false
    @State private var pickedDate = Date()

    private var schedule: Schedule? { model.schedule }

    private var currentWeek: Int? {
        Weeks.currentWeek(firstWeekMonday: model.firstWeekMonday)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("教务信息") {
                    InfoRowView(label: "学期", value: schedule?.weekInfo.term ?? "—")
                    InfoRowView(label: "时间模板", value: schedule?.weekInfo.timeTemplate ?? "—")
                    InfoRowView(label: "数据更新", value: fetchedAtText)
                }

                section("开学日期") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("第一周的周一")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(mondayText)
                                .font(.footnote)
                                .foregroundColor(model.firstWeekMonday == nil ? .red : .secondary)
                        }
                        Spacer()
                        Button("选择日期") {
                            pickedDate = model.firstWeekMonday ?? Weeks.mondayOf(Date())
                            showDatePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Text(currentWeek.map { "用于计算当前周次，当前为第 \($0) 周" }
                        ?? "用于计算当前周次，未设置前课表不做周次过滤")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                section("账号") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前账号")
                                .font(.body)
                            Text(model.account.isEmpty ? "未记住账号" : model.account)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("退出登录") {
                            model.logout()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("课表 v0.1.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Self.disclaimer)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)

                    Link(destination: URL(string: "https://github.com/sonoma2727/Timetable")!) {
                        Text("项目地址：github.com/sonoma2727/Timetable")
                            .font(.caption2)
                            .foregroundColor(Color.accentColor)
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(Color.accentColor)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var datePickerSheet: some View {
        VStack(spacing: 12) {
            DatePicker(
                "",
                selection: $pickedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            HStack {
                Button("取消") {
                    showDatePicker = false
                }
                Spacer()
                Button("确定") {
                    model.setFirstWeekMonday(date: pickedDate)
                    showDatePicker = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }

    private var mondayText: String {
        guard let monday = model.firstWeekMonday else { return "未设置" }
        return Self.dateFormatter.string(from: monday)
    }

    private var fetchedAtText: String {
        guard let fetchedAt = schedule?.fetchedAt, fetchedAt > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(fetchedAt) / 1000)
        return Self.dateTimeFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    static let disclaimer = """
    免责声明：
    1. 本项目为个人学习用途的第三方工具，与学校及其教务系统官方无关，非官方产品。
    2. 仅限使用者本人账号自用；禁止用于查询他人数据、批量抓取或任何商业用途。
    3. 使用者应遵守学校规章制度与国家法律法规，因违规使用产生的后果自行承担。
    4. 课表数据实时来源于教务系统，可能存在滞后或偏差，一切以教务系统及学校正式发布为准。
    5. 账号凭据仅加密保存在本机（iOS Keychain），本软件不收集、不上传任何数据；因本机失陷（越狱、恶意软件等）导致的凭据风险由使用者自担。
    6. 教务系统升级或接口变更可能导致本软件失效，不保证持续可用。
    7. 本软件按“现状”提供，不作任何明示或暗示担保；对因使用产生的直接或间接损失，开发者不承担责任。
    """
}

struct InfoRowView: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.footnote)
            Spacer(minLength: 0)
        }
    }
}
