// HolidayManager.swift
import Foundation
import SwiftUI

struct HolidayManager {
    
    // 고정 공휴일 (MM-dd)
    private static let fixedHolidays: [String: String] = [
        "01-01": "신정",
        "03-01": "삼일절",
        "05-05": "어린이날",
        "06-06": "현충일",
        "08-15": "광복절",
        "10-03": "개천절",
        "10-09": "한글날",
        "12-25": "크리스마스"
    ]
    
    // 음력 기반 공휴일 (yyyy-MM-dd)
    private static let lunarHolidays: [String: String] = [
        // 2024
        "2024-02-09": "설날 전날", "2024-02-10": "설날", "2024-02-11": "설날 다음날",
        "2024-05-06": "대체공휴일", "2024-05-15": "부처님오신날",
        "2024-09-16": "추석 전날", "2024-09-17": "추석", "2024-09-18": "추석 다음날",
        // 2025
        "2025-01-28": "설날 전날", "2025-01-29": "설날", "2025-01-30": "설날 다음날",
        "2025-03-03": "대체공휴일", "2025-05-06": "부처님오신날",
        "2025-10-05": "추석 전날", "2025-10-06": "추석", "2025-10-07": "추석 다음날", "2025-10-08": "대체공휴일",
        // 2026
        "2026-02-16": "설날 전날", "2026-02-17": "설날", "2026-02-18": "설날 다음날",
        "2026-05-25": "부처님오신날",
        "2026-09-24": "추석 전날", "2026-09-25": "추석", "2026-09-26": "추석 다음날",
        // 2027
        "2027-02-05": "설날 전날", "2027-02-06": "설날", "2027-02-07": "설날 다음날",
        "2027-05-13": "부처님오신날",
        "2027-10-14": "추석 전날", "2027-10-15": "추석", "2027-10-16": "추석 다음날",
    ]
    
    static func holiday(for date: Date) -> String? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day   = calendar.component(.day, from: date)
        let year  = calendar.component(.year, from: date)
        
        let mmdd  = String(format: "%02d-%02d", month, day)
        let full  = String(format: "%04d-%02d-%02d", year, month, day)
        
        return lunarHolidays[full] ?? fixedHolidays[mmdd]
    }
    
    static func isHoliday(_ date: Date) -> Bool {
        holiday(for: date) != nil
    }
}
