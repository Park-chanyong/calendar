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
    var icon: String
    var colorName: String

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
                            Text(event.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
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

// MARK: - Bundle

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidget()
    }
}
