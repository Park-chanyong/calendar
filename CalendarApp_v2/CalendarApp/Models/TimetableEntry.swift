// TimetableEntry.swift
import Foundation
import SwiftUI

struct TimetableEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var weekday: Int        // 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var colorName: String
    var memo: String = ""
    var isImportant: Bool = false

    var startTotalMinutes: Int { startHour * 60 + startMinute }
    var endTotalMinutes: Int   { endHour   * 60 + endMinute   }
    var durationMinutes: Int   { max(30, endTotalMinutes - startTotalMinutes) }

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

    // 기존 데이터(isImportant 없는)와 호환
    enum CodingKeys: String, CodingKey {
        case id, title, weekday, startHour, startMinute, endHour, endMinute, colorName, memo, isImportant
    }

    init(id: UUID = UUID(), title: String, weekday: Int,
         startHour: Int, startMinute: Int, endHour: Int, endMinute: Int,
         colorName: String, memo: String = "", isImportant: Bool = false) {
        self.id          = id
        self.title       = title
        self.weekday     = weekday
        self.startHour   = startHour
        self.startMinute = startMinute
        self.endHour     = endHour
        self.endMinute   = endMinute
        self.colorName   = colorName
        self.memo        = memo
        self.isImportant = isImportant
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
        memo        = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""
        isImportant = try c.decodeIfPresent(Bool.self,   forKey: .isImportant) ?? false
    }
}
