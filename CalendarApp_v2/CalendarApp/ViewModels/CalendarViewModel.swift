// CalendarViewModel.swift
import Foundation
import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var events: [Event] = [] {
        didSet { saveEvents() }
    }
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var viewMode: ViewMode = .month
    
    enum ViewMode {
        case month, week
    }
    
    private let saveKey = "CalendarEvents"
    
    init() {
        loadEvents()
    }
    
    // MARK: - CRUD
    func addEvent(_ event: Event) {
        events.append(event)
        if event.notificationEnabled {
            NotificationManager.shared.scheduleNotification(for: event)
        }
    }
    
    func deleteEvent(_ event: Event) {
        NotificationManager.shared.removeNotification(for: event)
        events.removeAll { $0.id == event.id }
    }
    
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            NotificationManager.shared.removeNotification(for: events[index])
            events[index] = event
            if event.notificationEnabled {
                NotificationManager.shared.scheduleNotification(for: event)
            }
        }
    }
    
    // MARK: - Filtering
    func events(for date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func events(forWeekOf date: Date) -> [Event] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return events.filter { weekInterval.contains($0.date) }
    }
    
    // MARK: - Navigation
    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    func previousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func nextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func goToToday() {
        selectedDate = Date()
        currentMonth = Date()
    }
    
    // MARK: - Month Helpers
    func daysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    func daysInWeek(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekInterval.start)
        }
    }
    
    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    func weekTitle(for date: Date) -> String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: calendar.date(byAdding: .day, value: 6, to: weekInterval.start) ?? weekInterval.end)
        return "\(start) ~ \(end)"
    }
    
    // MARK: - Persistence
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
}
