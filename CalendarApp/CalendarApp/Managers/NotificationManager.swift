// NotificationManager.swift
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("알림 권한 오류: \(error)")
            }
        }
    }
    
    func scheduleNotification(for event: Event) {
        // 정시 알림
        schedule(
            id: event.id.uuidString,
            title: "📅 일정 알림",
            body: event.title,
            subtitle: event.memo.isEmpty ? nil : event.memo,
            at: event.date
        )
        
        // 미리 알림
        if event.notificationEnabled, event.reminderOption != .none {
            let reminderDate = event.date.addingTimeInterval(-Double(event.reminderOption.rawValue) * 60)
            schedule(
                id: "\(event.id.uuidString)_reminder",
                title: "⏰ \(event.reminderOption.label) 알림",
                body: event.title,
                subtitle: event.memo.isEmpty ? nil : event.memo,
                at: reminderDate
            )
        }
    }
    
    private func schedule(id: String, title: String, body: String, subtitle: String?, at date: Date) {
        guard date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("알림 등록 오류: \(error)") }
        }
    }
    
    func removeNotification(for event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [event.id.uuidString, "\(event.id.uuidString)_reminder"]
        )
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
