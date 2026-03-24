// Event.swift
import Foundation
import SwiftUI

enum EventCategory: String, Codable, CaseIterable {
    case general    = "general"
    case exam       = "exam"
    case assignment = "assignment"

    var label: String {
        switch self {
        case .general:    return "일반"
        case .exam:       return "시험"
        case .assignment: return "과제"
        }
    }

    var sfSymbol: String {
        switch self {
        case .general:    return "calendar"
        case .exam:       return "pencil.and.ruler.fill"
        case .assignment: return "checklist"
        }
    }

    var badgeColor: Color {
        switch self {
        case .general:    return .blue
        case .exam:       return .red
        case .assignment: return .orange
        }
    }
}

enum ReminderOption: Int, Codable, CaseIterable {
    case none          = 0
    case tenMinutes    = 10
    case thirtyMinutes = 30
    case oneHour       = 60
    case twoHours      = 120
    case oneDay        = 1440
    case twoDays       = 2880
    case threeDays     = 4320
    case oneWeek       = 10080

    var label: String {
        switch self {
        case .none:          return "없음"
        case .tenMinutes:    return "10분 전"
        case .thirtyMinutes: return "30분 전"
        case .oneHour:       return "1시간 전"
        case .twoHours:      return "2시간 전"
        case .oneDay:        return "하루 전"
        case .twoDays:       return "이틀 전"
        case .threeDays:     return "삼일 전"
        case .oneWeek:       return "일주일 전"
        }
    }
}

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var location: String = ""
    var memo: String = ""
    var icon: String = "calendar"
    var colorName: String = "blue"
    var category: EventCategory = .general
    var subjectName: String = ""        // 시험/과제 연결 과목
    var endDate: Date? = nil            // 시험: 종료 시간 (범위 표기용)
    var notificationEnabled: Bool = false
    var reminderOption: ReminderOption = .none

    var color: Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }

    // 기존 데이터(category/subjectName 없는)와 호환
    enum CodingKeys: String, CodingKey {
        case id, title, date, location, memo, icon, colorName
        case category, subjectName, endDate, notificationEnabled, reminderOption
    }

    init(id: UUID = UUID(), title: String, date: Date,
         location: String = "", memo: String = "",
         icon: String = "calendar", colorName: String = "blue",
         category: EventCategory = .general, subjectName: String = "",
         endDate: Date? = nil,
         notificationEnabled: Bool = false, reminderOption: ReminderOption = .none) {
        self.id = id; self.title = title; self.date = date
        self.location = location; self.memo = memo
        self.icon = icon; self.colorName = colorName
        self.category = category; self.subjectName = subjectName
        self.endDate = endDate
        self.notificationEnabled = notificationEnabled
        self.reminderOption = reminderOption
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        date        = try c.decode(Date.self,   forKey: .date)
        location    = try c.decodeIfPresent(String.self,        forKey: .location)    ?? ""
        memo        = try c.decodeIfPresent(String.self,        forKey: .memo)        ?? ""
        icon        = try c.decodeIfPresent(String.self,        forKey: .icon)        ?? "calendar"
        colorName   = try c.decodeIfPresent(String.self,        forKey: .colorName)   ?? "blue"
        category    = try c.decodeIfPresent(EventCategory.self, forKey: .category)    ?? .general
        subjectName = try c.decodeIfPresent(String.self,        forKey: .subjectName) ?? ""
        endDate     = try c.decodeIfPresent(Date.self,          forKey: .endDate)
        notificationEnabled = try c.decodeIfPresent(Bool.self,          forKey: .notificationEnabled) ?? false
        reminderOption      = try c.decodeIfPresent(ReminderOption.self, forKey: .reminderOption)     ?? .none
    }
}

let availableIcons = [
    "calendar", "star.fill", "heart.fill", "bolt.fill",
    "flag.fill", "bell.fill", "tag.fill", "briefcase.fill",
    "house.fill", "person.fill", "cart.fill", "airplane",
    "car.fill", "fork.knife", "gamecontroller.fill", "music.note"
]

let availableColors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
