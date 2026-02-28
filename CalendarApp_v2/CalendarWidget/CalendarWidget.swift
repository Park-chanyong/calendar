// CalendarWidget.swift
import WidgetKit
import SwiftUI

// MARK: - Model (mirrors app's Event, Codable only)

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
    let date: Date
    let todayEvents: [WidgetEvent]
    let weekDays: [Date]
}

// MARK: - Provider

struct CalendarProvider: TimelineProvider {
    private let appGroupID = "group.com.example3.CalendarApp"
    private let saveKey    = "CalendarEvents"

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), todayEvents: [], weekDays: weekDays(for: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        completion(Timeline(entries: [entry(for: now)], policy: .after(nextHour)))
    }

    // MARK: Private helpers

    private func entry(for date: Date) -> CalendarEntry {
        let events = loadEvents()
        let today = events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return CalendarEntry(date: date, todayEvents: today, weekDays: weekDays(for: date))
    }

    private func loadEvents() -> [WidgetEvent] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([WidgetEvent].self, from: data)
        else { return [] }
        return decoded
    }

    private func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
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

    // MARK: - Small (2×2): 날짜 + 다음 일정 1개

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeekString(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(dayString(entry.date))
                    .font(.title3.bold())
            }
            Spacer()
            if let event = entry.todayEvents.first {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: event.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(event.color)
                        Text(timeString(event.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(event.title)
                        .font(.caption.bold())
                        .lineLimit(2)
                }
            } else {
                Text("일정 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .widgetURL(dateURL(entry.date))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Medium (4×2): 이번 주 행 + 일정 3개

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            Divider()
            weekRowView
            Divider()
            eventList(limit: 3)
        }
        .padding()
        .widgetURL(dateURL(entry.date))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Large (4×4): 이번 주 행 + 일정 7개

    private var largeBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            Divider()
            weekRowView
            Divider()
            eventList(limit: 7)
        }
        .padding()
        .widgetURL(dateURL(entry.date))
        .containerBackground(.background, for: .widget)
    }

    // MARK: - Shared sub-views

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeekString(entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dayString(entry.date))
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(.blue)
        }
    }

    private var weekRowView: some View {
        HStack(spacing: 0) {
            ForEach(entry.weekDays, id: \.self) { day in
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: 2) {
                    Text(shortWeekdayString(day))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(dayNumberString(day))
                        .font(.system(size: 13, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? .white : .primary)
                        .frame(width: 24, height: 24)
                        .background(isToday ? Color.blue : Color.clear, in: Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func eventList(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.todayEvents.isEmpty {
                Text("일정 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(entry.todayEvents.prefix(limit)) { event in
                    Link(destination: dateURL(event.date)) {
                        HStack(spacing: 6) {
                            Image(systemName: event.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(event.color)
                                .frame(width: 14)
                            Text(event.title)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(timeString(event.date))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func dateURL(_ date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return URL(string: "calendarapp://date/\(formatter.string(from: date))")!
    }

    // MARK: - Formatters

    private func dayOfWeekString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func shortWeekdayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func dayNumberString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Widget Declaration

struct CalendarWidget: Widget {
    let kind = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("캘린더")
        .description("이번 주와 오늘 일정을 확인하세요.")
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
