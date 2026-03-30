// CalendarWidget.swift
import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Constants

private let appGroupID   = "group.com.example3.CalendarApp"
private let saveKey      = "CalendarEvents"
private let displayDateKey = "widgetDisplayDate"

// MARK: - App Intents (이전/다음 날 이동)

struct PreviousDayIntent: AppIntent {
    static var title: LocalizedStringResource = "이전 날"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroupID)
        let current  = defaults?.object(forKey: displayDateKey) as? Date ?? Date()
        let previous = Calendar.current.date(byAdding: .day, value: -1, to: current) ?? current
        defaults?.set(previous, forKey: displayDateKey)
        return .result()
    }
}

struct NextDayIntent: AppIntent {
    static var title: LocalizedStringResource = "다음 날"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroupID)
        let current  = defaults?.object(forKey: displayDateKey) as? Date ?? Date()
        let next     = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? current
        defaults?.set(next, forKey: displayDateKey)
        return .result()
    }
}

// MARK: - Model

struct WidgetEvent: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    var memo: String
    var icon: String
    var colorName: String

    enum CodingKeys: String, CodingKey {
        case id, title, date, memo, icon, colorName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        title     = try c.decode(String.self, forKey: .title)
        date      = try c.decode(Date.self,   forKey: .date)
        memo      = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""
        icon      = try c.decode(String.self, forKey: .icon)
        colorName = try c.decode(String.self, forKey: .colorName)
    }

    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green":  return .green
        case "blue":   return .blue
        case "purple": return .purple
        case "pink":   return .pink
        default:       return .blue
        }
    }
}

// MARK: - Timeline Entry

struct CalendarEntry: TimelineEntry {
    let date: Date           // 타임라인 날짜
    let displayDate: Date    // 위젯에 표시할 날짜
    let todayEvents: [WidgetEvent]
    let weekDays: [Date]
}

// MARK: - Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now      = Date()
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        completion(Timeline(entries: [entry(for: now)], policy: .after(nextHour)))
    }

    // MARK: Private

    private func entry(for timelineDate: Date) -> CalendarEntry {
        let defaults    = UserDefaults(suiteName: appGroupID)
        let displayDate = defaults?.object(forKey: displayDateKey) as? Date ?? timelineDate
        let events      = loadEvents().filter { Calendar.current.isDate($0.date, inSameDayAs: displayDate) }
        return CalendarEntry(
            date: timelineDate,
            displayDate: displayDate,
            todayEvents: events,
            weekDays: weekDays(for: displayDate)
        )
    }

    private func loadEvents() -> [WidgetEvent] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data     = defaults.data(forKey: saveKey),
              let decoded  = try? JSONDecoder().decode([WidgetEvent].self, from: data)
        else { return [] }
        return decoded
    }

    private func weekDays(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }
}

// MARK: - Widget View

struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalendarEntry

    private var calendar: Calendar { .current }

    var body: some View {
        switch family {
        case .systemSmall:  smallBody
        case .systemLarge:  largeBody
        default:            mediumBody
        }
    }

    // MARK: - Small

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(intent: PreviousDayIntent()) {
                    Image(systemName: "chevron.left").font(.body)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                VStack(spacing: 1) {
                    Text(dayOfWeekString(entry.displayDate))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(dayString(entry.displayDate))
                        .font(.subheadline.bold())
                }

                Spacer()

                Button(intent: NextDayIntent()) {
                    Image(systemName: "chevron.right").font(.body)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            Spacer()

            if let event = entry.todayEvents.first {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: event.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(event.color)
                        Text(timeString(event.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(event.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                }
            } else {
                Text("일정 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .widgetURL(dateURL(entry.displayDate))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Medium

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            navHeaderView
            Divider()
            weekRowView
            Divider()
            eventList(limit: 3)
        }
        .padding()
        .widgetURL(dateURL(entry.displayDate))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Large

    private var largeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            navHeaderView
            Divider()
            weekRowView
            Divider()
            eventList(limit: 7)
        }
        .padding()
        .widgetURL(dateURL(entry.displayDate))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Shared sub-views

    private var navHeaderView: some View {
        HStack {
            Button(intent: PreviousDayIntent()) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(dayOfWeekString(entry.displayDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(dayString(entry.displayDate))
                    .font(.title.bold())
            }

            Spacer()

            Button(intent: NextDayIntent()) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var weekRowView: some View {
        HStack(spacing: 0) {
            ForEach(entry.weekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: entry.displayDate)
                let isToday    = calendar.isDateInToday(day)
                VStack(spacing: 2) {
                    Text(shortWeekdayString(day))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(dayNumberString(day))
                        .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)
                        .frame(width: 28, height: 28)
                        .background(isSelected ? Color.blue : Color.clear, in: Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func eventList(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.todayEvents.isEmpty {
                Text("일정 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(entry.todayEvents.prefix(limit)) { event in
                    Link(destination: dateURL(event.date)) {
                        HStack(spacing: 6) {
                            Image(systemName: event.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(event.color)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                if !event.memo.isEmpty {
                                    Text(event.memo)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(timeString(event.date))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Helpers

    private func dateURL(_ date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return URL(string: "calendarapp://date/\(formatter.string(from: date))")!
    }

    private func dayOfWeekString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE"; f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M월 d일"; f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    private func shortWeekdayString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    private func dayNumberString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Widget

struct CalendarWidget: Widget {
    let kind = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("캘린더")
        .description("날짜를 이동하며 일정을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timetable Widget

private let timetableKey = "TimetableEntries"

// 위젯용 시간표 항목 (TimetableEntry와 동일 JSON 구조)
struct WidgetTimetableEntry: Identifiable, Codable {
    var id: UUID
    var title: String
    var weekday: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var colorName: String
    var isImportant: Bool

    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green":  return .green
        case "blue":   return .blue
        case "purple": return .purple
        case "pink":   return .pink
        default:       return .blue
        }
    }

    var timeRange: String {
        String(format: "%02d:%02d–%02d:%02d", startHour, startMinute, endHour, endMinute)
    }

    var location: String
    var memo: String

    enum CodingKeys: String, CodingKey {
        case id, title, weekday, startHour, startMinute, endHour, endMinute, colorName, isImportant, location, memo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        weekday     = try c.decode(Int.self,    forKey: .weekday)
        startHour   = try c.decode(Int.self,    forKey: .startHour)
        startMinute = try c.decode(Int.self,    forKey: .startMinute)
        endHour     = try c.decode(Int.self,    forKey: .endHour)
        endMinute   = try c.decode(Int.self,    forKey: .endMinute)
        colorName   = try c.decode(String.self, forKey: .colorName)
        isImportant = try c.decodeIfPresent(Bool.self,   forKey: .isImportant) ?? false
        location    = try c.decodeIfPresent(String.self, forKey: .location)    ?? ""
        memo        = try c.decodeIfPresent(String.self, forKey: .memo)        ?? ""
    }
}

// 월~금 전체 주간 시간표를 담는 TimelineEntry
struct TimetableTimelineEntry: TimelineEntry {
    let date:        Date
    let weekEntries: [Int: [WidgetTimetableEntry]]  // 1=월 … 5=금
}

struct TimetableProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimetableTimelineEntry { makeEntry(for: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (TimetableTimelineEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableTimelineEntry>) -> Void) {
        let now      = Date()
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        completion(Timeline(entries: [makeEntry(for: now)], policy: .after(nextHour)))
    }

    private func makeEntry(for date: Date) -> TimetableTimelineEntry {
        let all = loadTimetable()
        var grouped: [Int: [WidgetTimetableEntry]] = [:]
        for w in 1...5 {
            grouped[w] = all
                .filter { $0.weekday == w }
                .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }
        }
        return TimetableTimelineEntry(date: date, weekEntries: grouped)
    }

    private func loadTimetable() -> [WidgetTimetableEntry] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data     = defaults.data(forKey: timetableKey),
              let decoded  = try? JSONDecoder().decode([WidgetTimetableEntry].self, from: data)
        else { return [] }
        return decoded
    }
}

// 앱 TimetableView와 동일한 그리드 레이아웃을 위젯으로 재현
struct TimetableWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimetableTimelineEntry

    private let startHour = 9
    private let endHour   = 19
    private let weekdays  = [(1,"월"),(2,"화"),(3,"수"),(4,"목"),(5,"금")]

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: entry.date) - 1
    }

    // MARK: - body

    var body: some View {
        GeometryReader { geo in
            let small      = family == .systemSmall
            let pad: CGFloat   = 5
            let axisW: CGFloat = small ? 24 : 30
            let hdrH:  CGFloat = small ? 18 : 22
            let fs:    CGFloat = small ? 10 : 12
            let availW = geo.size.width  - pad * 2
            let availH = geo.size.height - pad * 2
            let gridH  = availH - hdrH - 1
            let hourH  = gridH / CGFloat(endHour - startHour)
            let colW   = (availW - axisW) / 5

            gridContent(small: small, axisW: axisW, hdrH: hdrH,
                        availW: availW, availH: availH,
                        gridH: gridH, hourH: hourH, colW: colW, fs: fs)
                .padding(pad)
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "calendarapp://timetable"))
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func gridContent(small: Bool, axisW: CGFloat, hdrH: CGFloat,
                              availW: CGFloat, availH: CGFloat,
                              gridH: CGFloat, hourH: CGFloat,
                              colW: CGFloat, fs: CGFloat) -> some View {
        VStack(spacing: 0) {
            weekdayHeader(small: small, axisW: axisW, hdrH: hdrH, colW: colW)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 0.5)
            timeGrid(axisW: axisW, availW: availW,
                     gridH: gridH, hourH: hourH, colW: colW, fs: fs)
        }
        .frame(width: availW, height: availH)
    }

    @ViewBuilder
    private func weekdayHeader(small: Bool, axisW: CGFloat,
                                hdrH: CGFloat, colW: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: axisW)
            ForEach(weekdays, id: \.0) { (wNum, wName) in
                Text(wName)
                    .font(.system(size: small ? 12 : 14, weight: .semibold))
                    .foregroundStyle(todayWeekday == wNum ? Color.blue : Color.secondary)
                    .frame(width: colW)
            }
        }
        .frame(height: hdrH)
    }

    @ViewBuilder
    private func timeGrid(axisW: CGFloat, availW: CGFloat,
                          gridH: CGFloat, hourH: CGFloat,
                          colW: CGFloat, fs: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            hourLines(axisW: axisW, availW: availW, hourH: hourH, fs: fs)
            columnDividers(axisW: axisW, colW: colW, gridH: gridH)
            entryBlocks(axisW: axisW, colW: colW, hourH: hourH, fs: fs)
        }
        .frame(width: availW, height: gridH)
    }

    @ViewBuilder
    private func hourLines(axisW: CGFloat, availW: CGFloat,
                           hourH: CGFloat, fs: CGFloat) -> some View {
        ForEach(startHour...endHour, id: \.self) { hour in
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: availW - axisW, height: 0.5)
                .offset(x: axisW, y: CGFloat(hour - startHour) * hourH)
            Text("\(hour)")
                .font(.system(size: fs))
                .foregroundStyle(Color.secondary)
                .frame(width: axisW - 2, alignment: .trailing)
                .offset(y: CGFloat(hour - startHour) * hourH)
        }
    }

    @ViewBuilder
    private func columnDividers(axisW: CGFloat, colW: CGFloat, gridH: CGFloat) -> some View {
        ForEach(1..<5, id: \.self) { i in
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 0.5, height: gridH)
                .offset(x: axisW + CGFloat(i) * colW)
        }
    }

    @ViewBuilder
    private func entryBlocks(axisW: CGFloat, colW: CGFloat,
                              hourH: CGFloat, fs: CGFloat) -> some View {
        ForEach(weekdays, id: \.0) { (wNum, _) in
            ForEach(entry.weekEntries[wNum] ?? []) { item in
                entryBlock(item: item, colW: colW,
                           blkH: blockHeight(item: item, hourH: hourH),
                           hourH: hourH, fs: fs)
                    .offset(x: axisW + CGFloat(wNum - 1) * colW + 0.5,
                            y: blockY(item: item, hourH: hourH))
            }
        }
    }

    @ViewBuilder
    private func entryBlock(item: WidgetTimetableEntry, colW: CGFloat,
                            blkH: CGFloat, hourH: CGFloat, fs: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(item.color.opacity(0.18))
            Rectangle()
                .fill(item.color)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
            if blkH >= hourH * 0.6 {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 2) {
                        if item.isImportant {
                            Image(systemName: "star.fill")
                                .font(.system(size: fs - 2))
                                .foregroundStyle(.yellow)
                        }
                        Text(item.title)
                            .font(.system(size: fs, weight: .semibold))
                            .foregroundStyle(item.color)
                            .lineLimit(2)
                    }
                    if blkH >= hourH * 1.0 && !item.location.isEmpty {
                        Text(item.location)
                            .font(.system(size: fs - 1))
                            .foregroundStyle(item.color.opacity(0.75))
                            .lineLimit(1)
                    }
                    if blkH >= hourH * 1.5 && !item.memo.isEmpty {
                        Text(item.memo)
                            .font(.system(size: fs - 1))
                            .foregroundStyle(item.color.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 4)
                .padding(.top, 1)
            }
        }
        .frame(width: colW - 1, height: blkH)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    // MARK: - Helpers

    private func blockY(item: WidgetTimetableEntry, hourH: CGFloat) -> CGFloat {
        CGFloat(item.startHour - startHour) * hourH
            + CGFloat(item.startMinute) * hourH / 60
    }

    private func blockHeight(item: WidgetTimetableEntry, hourH: CGFloat) -> CGFloat {
        let dur = CGFloat((item.endHour * 60 + item.endMinute)
                       - (item.startHour * 60 + item.startMinute))
        return max(hourH * 0.5, dur * hourH / 60)
    }
}

struct TimetableWidget: Widget {
    let kind = "TimetableWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            TimetableWidgetView(entry: entry)
        }
        .configurationDisplayName("시간표")
        .description("오늘의 고정 시간표를 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Bundle

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidget()
        TimetableWidget()
    }
}

