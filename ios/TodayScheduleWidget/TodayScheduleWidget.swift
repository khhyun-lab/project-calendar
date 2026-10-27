import WidgetKit
import SwiftUI

// MARK: - Models

struct ScheduleItem: Identifiable, Decodable {
    var id: String { (title ?? "") + (start ?? "") }
    let title: String?
    let start: String?
    let end: String?
    let startMinutes: Int?
    let endMinutes: Int?
    let color: Int?
    let isShift: Bool?
}

struct MonthCalendarData: Decodable {
    let year: Int
    let month: Int
    let daysInMonth: Int
    let firstWeekday: Int
    let todayDay: Int
    let scheduledDays: [Int]
    let shiftDays: [Int]

    static var placeholder: MonthCalendarData {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        let day = cal.component(.day, from: now)
        return MonthCalendarData(
            year: year,
            month: month,
            daysInMonth: 31,
            firstWeekday: 1,
            todayDay: day,
            scheduledDays: [day],
            shiftDays: []
        )
    }
}

extension Color {
    init(argb: Int) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a > 0 ? a : 1.0)
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    let appGroupId = "group.com.today_schedule"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            dateText: "10월 27일 (월)",
            currentTimeText: "14:30",
            currentTimeMinutes: 870,
            scheduleCount: 1,
            schedules: [
                ScheduleItem(title: "주간근무", start: "09:00", end: "18:00", startMinutes: 540, endMinutes: 1080, color: 0xFF3B82F6, isShift: true)
            ],
            monthData: MonthCalendarData.placeholder
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(getCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = getCurrentEntry()
        // 15분마다 자동 갱신 + 앱 변경 시 즉각 갱신
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getCurrentEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard

        let dateText = userDefaults.string(forKey: "today_date_text") ?? {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일 (E)"
            return formatter.string(from: Date())
        }()

        let count = userDefaults.integer(forKey: "today_schedule_count")

        let currentTimeText = userDefaults.string(forKey: "current_time_text") ?? {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: Date())
        }()

        let currentTimeMinutes: Int = {
            let val = userDefaults.integer(forKey: "current_time_minutes")
            if val > 0 { return val }
            let cal = Calendar.current
            let now = Date()
            return cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        }()

        var schedules: [ScheduleItem] = []
        if let jsonString = userDefaults.string(forKey: "today_schedules_json"),
           let data = jsonString.data(using: .utf8) {
            schedules = (try? JSONDecoder().decode([ScheduleItem].self, from: data)) ?? []
        }

        var monthData = MonthCalendarData.placeholder
        if let jsonString = userDefaults.string(forKey: "month_calendar_json"),
           let data = jsonString.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(MonthCalendarData.self, from: data) {
            monthData = parsed
        }

        return SimpleEntry(
            date: Date(),
            dateText: dateText,
            currentTimeText: currentTimeText,
            currentTimeMinutes: currentTimeMinutes,
            scheduleCount: count,
            schedules: schedules,
            monthData: monthData
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dateText: String
    let currentTimeText: String
    let currentTimeMinutes: Int
    let scheduleCount: Int
    let schedules: [ScheduleItem]
    let monthData: MonthCalendarData
}

// MARK: - Arc Shape for 24-Hour Circular Dial

struct DialArcShape: Shape {
    let startMinutes: Int
    let endMinutes: Int
    let strokeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) - strokeWidth) / 2

        // 24시간: 0분 = 상단 (-90도)
        let startDeg = -90.0 + (Double(startMinutes) / 1440.0) * 360.0
        var endDeg = -90.0 + (Double(endMinutes) / 1440.0) * 360.0
        if endDeg <= startDeg {
            endDeg += 360.0
        }

        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startDeg),
            endAngle: Angle(degrees: endDeg),
            clockwise: false
        )
        return path
    }
}

// MARK: - Native Liquid Glass Widget Views

struct TodayScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                // 4x2 캘린더: Apple Liquid Glass 네이티브 뷰
                NativeMediumCalendarView(entry: entry)

            case .systemLarge:
                // 4x4 24시간 원형 일정: Apple Liquid Glass 네이티브 다이얼
                NativeLargeCircularDialView(entry: entry)

            default:
                NativeMediumCalendarView(entry: entry)
            }
        }
    }
}

// =============================================================================
// 1. 4x2 네이티브 캘린더 뷰 (Apple Liquid Glass)
// =============================================================================
struct NativeMediumCalendarView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack(spacing: 6) {
            // 헤더: 월 / 연도 및 오늘 날짜 캡슐
            HStack(alignment: .firstTextBaseline) {
                Text("\(entry.monthData.month)월")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(String(entry.monthData.year))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                // 플로팅 리퀴드 글래스 캡슐
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                    Text("오늘 \(entry.monthData.todayDay)일")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
            }
            .padding(.horizontal, 4)

            // 요일 바
            HStack(spacing: 0) {
                Text("일").foregroundColor(.red).font(.system(size: 10, weight: .bold)).frame(maxWidth: .infinity)
                Text("월").foregroundColor(.secondary).font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity)
                Text("화").foregroundColor(.secondary).font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity)
                Text("수").foregroundColor(.secondary).font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity)
                Text("목").foregroundColor(.secondary).font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity)
                Text("금").foregroundColor(.secondary).font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity)
                Text("토").foregroundColor(.blue).font(.system(size: 10, weight: .bold)).frame(maxWidth: .infinity)
            }

            Divider().opacity(0.3)

            // 5주 달력 그리드
            VStack(spacing: 4) {
                ForEach(0..<5) { week in
                    HStack(spacing: 0) {
                        ForEach(0..<7) { dayOfWeek in
                            let idx = week * 7 + dayOfWeek
                            let dayNum = idx - entry.monthData.firstWeekday + 1

                            if dayNum >= 1 && dayNum <= entry.monthData.daysInMonth {
                                let isToday = (dayNum == entry.monthData.todayDay)
                                let hasSchedule = entry.monthData.scheduledDays.contains(dayNum)
                                let hasShift = entry.monthData.shiftDays.contains(dayNum)

                                VStack(spacing: 1.5) {
                                    ZStack {
                                        if isToday {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 19, height: 19)
                                                .shadow(color: Color.red.opacity(0.5), radius: 3)
                                        }

                                        Text("\(dayNum)")
                                            .font(.system(size: 11, weight: isToday ? .black : .bold, design: .rounded))
                                            .foregroundColor(isToday ? .white : (dayOfWeek == 0 ? .red : (dayOfWeek == 6 ? .blue : .primary)))
                                    }

                                    // 일정 점
                                    Circle()
                                        .fill(hasShift ? Color.orange : Color.blue)
                                        .frame(width: 3.5, height: 3.5)
                                        .opacity(hasSchedule ? 1.0 : 0.0)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
    }
}

// =============================================================================
// 2. 4x4 네이티브 24시간 원형 다이얼 뷰 (Apple Liquid Glass)
// =============================================================================
struct NativeLargeCircularDialView: View {
    let entry: Provider.Entry

    var currentOrNextSchedule: ScheduleItem? {
        let nowMin = entry.currentTimeMinutes
        for s in entry.schedules {
            let start = s.startMinutes ?? 0
            let end = s.endMinutes ?? 1440
            if nowMin >= start && nowMin <= end {
                return s
            }
        }
        return entry.schedules.first
    }

    var body: some View {
        VStack(spacing: 8) {
            // 상단 헤더
            HStack {
                Text(entry.dateText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                    Text("일정 \(entry.scheduleCount)건")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 3.5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
            }
            .padding(.horizontal, 4)

            // 중앙: 초대형 24시간 원형 다이얼 차트
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let strokeW: CGFloat = 22

                ZStack {
                    // 1. 24시간 베이스 글래스 트랙
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: strokeW)
                        .frame(width: size - strokeW, height: size - strokeW)

                    // 2. 24시간 주요 숫자 마커 (24, 06, 12, 18)
                    let textR = (size - strokeW) / 2 + 13
                    ForEach([0, 6, 12, 18], id: \.self) { hour in
                        let deg = -90.0 + (Double(hour) / 24.0) * 360.0
                        let rad = deg * .pi / 180.0
                        let x = cos(rad) * textR
                        let y = sin(rad) * textR

                        Text(hour == 0 ? "24" : String(format: "%02d", hour))
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.secondary)
                            .offset(x: x, y: y)
                    }

                    // 3. 등록된 일정 아크(Arc) 그리기
                    ForEach(entry.schedules) { s in
                        DialArcShape(
                            startMinutes: s.startMinutes ?? 0,
                            endMinutes: s.endMinutes ?? 60,
                            strokeWidth: strokeW
                        )
                        .stroke(
                            Color(argb: s.color ?? 0xFF007AFF),
                            style: StrokeStyle(lineWidth: strokeW - 2, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                    }

                    // 4. 현재 시간 표시 바늘 (글로잉 포인터)
                    let pointerR = (size - strokeW) / 2
                    let pointerDeg = -90.0 + (Double(entry.currentTimeMinutes) / 1440.0) * 360.0
                    let pointerRad = pointerDeg * .pi / 180.0
                    let px = cos(pointerRad) * pointerR
                    let py = sin(pointerRad) * pointerR

                    Circle()
                        .fill(Color.red)
                        .frame(width: strokeW * 0.7, height: strokeW * 0.7)
                        .shadow(color: Color.red.opacity(0.7), radius: 4)
                        .overlay(Circle().fill(Color.white).frame(width: 5, height: 5))
                        .offset(x: px, y: py)

                    // 5. 다이얼 중심: 초대형 시간 & 일정 캡슐
                    VStack(spacing: 3) {
                        Text(entry.currentTimeText)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)

                        if let s = currentOrNextSchedule {
                            let title = (s.isShift ?? false) ? "[당직] \(s.title ?? "근무")" : (s.title ?? "일정")
                            let color = Color(argb: s.color ?? 0xFF007AFF)

                            HStack(spacing: 5) {
                                Circle().fill(color).frame(width: 6, height: 6)
                                Text(title)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule().stroke(color.opacity(0.6), lineWidth: 1.0)
                            )
                        } else {
                            Text("예정된 일정 없음")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .padding(14)
    }
}

// MARK: - Widget Definition

struct TodayScheduleWidget: Widget {
    let kind: String = "TodayScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayScheduleWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Apple 공식 Liquid Glass 머티리얼 (배경화면 실시간 블러)
                    Rectangle().fill(.ultraThinMaterial)
                }
        }
        .configurationDisplayName("올인원 스케줄")
        .description("Apple Liquid Glass 스타일 4x2 캘린더 및 4x4 24시간 원형 일정을 확인하세요.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
