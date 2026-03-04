// Event.swift
import Foundation
import SwiftUI

enum ReminderOption: Int, Codable, CaseIterable {
    case none = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case thirtyMinutes = 30

    var label: String {
        switch self {
        case .none: return "없음"
        case .fiveMinutes: return "5분 전"
        case .tenMinutes: return "10분 전"
        case .thirtyMinutes: return "30분 전"
        }
    }
}

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var memo: String = ""
    var icon: String = "calendar"
    var colorName: String = "blue"
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
}

let availableIcons = [
    "calendar", "star.fill", "heart.fill", "bolt.fill",
    "flag.fill", "bell.fill", "tag.fill", "briefcase.fill",
    "house.fill", "person.fill", "cart.fill", "airplane",
    "car.fill", "fork.knife", "gamecontroller.fill", "music.note"
]

let availableColors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
