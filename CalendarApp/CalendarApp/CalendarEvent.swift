import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: String          // "YYYY-MM-DD"
    var title: String
    var icon: String
    var color: String         // hex string
    var startTime: String     // "HH:mm"
    var endTime: String
    var memo: String
    var notify: Bool

    var swiftColor: Color {
        Color(hex: color) ?? .purple
    }
}

extension Color {
    init?(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexStr = hexStr.hasPrefix("#") ? String(hexStr.dropFirst()) : hexStr
        guard hexStr.count == 6, let intVal = UInt64(hexStr, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255
        let g = Double((intVal >> 8) & 0xFF) / 255
        let b = Double(intVal & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
