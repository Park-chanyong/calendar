import SwiftUI

struct CalendarGridView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    @ObservedObject var store: EventStore

    let accent: Color
    let accent2: Color
    let surface2: Color
    let textMain: Color
    let textSub: Color

    private let weekDays = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let cal = Calendar.current

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(daysInGrid(), id: \.offset) { item in
                DayCellView(
                    item: item,
                    selectedDate: $selectedDate,
                    store: store,
                    accent: accent,
                    accent2: accent2,
                    surface2: surface2,
                    textMain: textMain,
                    textSub: textSub
                )
            }
        }
        .padding(.vertical, 8)
    }

    struct DayItem {
        let offset: Int
        let date: Date?
        let dayNumber: Int
        let weekdayLabel: String
        let isCurrentMonth: Bool
    }

    func daysInGrid() -> [DayItem] {
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) - 1 // 0=Sun
        let daysInMonth = cal.range(of: .day, in: .month, for: currentMonth)!.count

        // Previous month days
        let prevMonthDate = cal.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let daysInPrevMonth = cal.range(of: .day, in: .month, for: prevMonthDate)!.count

        var items: [DayItem] = []

        // Fill previous month
        for i in 0..<firstWeekday {
            let day = daysInPrevMonth - (firstWeekday - 1 - i)
            items.append(DayItem(offset: -firstWeekday + i, date: nil, dayNumber: day,
                                 weekdayLabel: weekDays[i], isCurrentMonth: false))
        }

        // Current month
        for d in 1...daysInMonth {
            let date = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth)!
            let wd = cal.component(.weekday, from: date) - 1
            items.append(DayItem(offset: d, date: date, dayNumber: d,
                                 weekdayLabel: weekDays[wd], isCurrentMonth: true))
        }

        // Next month
        let total = items.count
        let rem = 7 - (total % 7 == 0 ? 7 : total % 7)
        for d in 1...max(rem, 1) {
            if rem == 7 { break }
            let wd = (total + d - 1) % 7
            items.append(DayItem(offset: 1000 + d, date: nil, dayNumber: d,
                                 weekdayLabel: weekDays[wd], isCurrentMonth: false))
        }

        return items
    }
}

struct DayCellView: View {
    let item: CalendarGridView.DayItem
    @Binding var selectedDate: Date
    @ObservedObject var store: EventStore

    let accent: Color
    let accent2: Color
    let surface2: Color
    let textMain: Color
    let textSub: Color

    private let cal = Calendar.current

    var isToday: Bool {
        guard let date = item.date else { return false }
        return cal.isDateInToday(date)
    }

    var isSelected: Bool {
        guard let date = item.date else { return false }
        return cal.isDate(date, inSameDayAs: selectedDate)
    }

    var dots: [Color] {
        guard let date = item.date else { return [] }
        return store.events(for: date).prefix(3).compactMap { Color(hex: $0.color) }
    }

    var weekdayColor: Color {
        switch item.weekdayLabel {
        case "일": return Color(hex: "#f76a8c")!
        case "토": return Color(hex: "#6a9ef7")!
        default:   return textSub
        }
    }

    var body: some View {
        Button {
            if let date = item.date { selectedDate = date }
        } label: {
            VStack(spacing: 2) {
                Text(item.weekdayLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : (item.isCurrentMonth ? weekdayColor : weekdayColor.opacity(0.3)))

                Text("\(item.dayNumber)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(
                        isSelected ? .white :
                        !item.isCurrentMonth ? Color(hex: "#c8c0e8")! :
                        (item.weekdayLabel == "일" ? Color(hex: "#f76a8c")! :
                         item.weekdayLabel == "토" ? Color(hex: "#6a9ef7")! : textMain)
                    )

                // Dots
                HStack(spacing: 2) {
                    ForEach(dots.indices, id: \.self) { i in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.85) : dots[i])
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: [accent, accent2],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    } else if isToday {
                        LinearGradient(
                            colors: [accent.opacity(0.25), accent2.opacity(0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : (isToday ? accent : Color.clear), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
