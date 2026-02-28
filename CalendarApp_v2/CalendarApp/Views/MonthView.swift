// MonthView.swift
import SwiftUI

struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false

    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { switchMonth(direction: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(viewModel.monthTitle(for: viewModel.currentMonth))
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button { switchMonth(direction: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal).padding(.top, 8).padding(.bottom, 16)

            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    Text(["일","월","화","수","목","금","토"][i])
                        .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                        .foregroundColor(i == 0 ? .red : i == 6 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            Divider()

            let days = viewModel.daysInMonth(for: viewModel.currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(0..<days.count, id: \.self) { idx in
                    if let date = days[idx] {
                        MonthDayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            events: viewModel.events(for: date),
                            weekdayIndex: idx % 7
                        )
                        .onTapGesture { viewModel.selectedDate = date }
                    } else {
                        Color.clear.frame(height: 60)
                    }
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isAnimating else { return }
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dragOffset = value.translation.width * 0.3
                        }
                    }
                    .onEnded { value in
                        guard !isAnimating else { return }
                        let dx = value.translation.width
                        if abs(dx) > abs(value.translation.height) {
                            if dx < -50 { switchMonth(direction: 1) }
                            else if dx > 50 { switchMonth(direction: -1) }
                            else { withAnimation(.spring(response: 0.3)) { dragOffset = 0 } }
                        } else {
                            withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                        }
                    }
            )
            .clipped()
        }
    }

    private func switchMonth(direction: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        let w = UIScreen.main.bounds.width
        let out: CGFloat = direction > 0 ? -w : w
        let inn: CGFloat = direction > 0 ?  w : -w
        withAnimation(.easeInOut(duration: 0.38)) { dragOffset = out }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            if direction > 0 { viewModel.nextMonth() } else { viewModel.previousMonth() }
            dragOffset = inn
            withAnimation(.easeInOut(duration: 0.38)) { dragOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { isAnimating = false }
        }
    }
}

#Preview {
    MonthView(viewModel: CalendarViewModel())
}

struct MonthDayCell: View {
    let date: Date; let isSelected: Bool; let isToday: Bool
    let events: [Event]; let weekdayIndex: Int

    private var holiday: String? { HolidayManager.holiday(for: date) }
    private var dayNum: Int { Calendar.current.component(.day, from: date) }
    private var isRed: Bool { holiday != nil || weekdayIndex == 0 }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday    { return .blue  }
        if isRed      { return .red   }
        if weekdayIndex == 6 { return .blue }
        return .primary
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("\(dayNum)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundColor(textColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(isSelected ? Color.blue : isToday ? Color.blue.opacity(0.15) : Color.clear))

            if let hol = holiday {
                Text(hol)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .red)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity).padding(.horizontal, 1)
            }

            HStack(spacing: 2) {
                ForEach(events.prefix(3)) { event in
                    Circle().fill(event.color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60, alignment: .top)
        .padding(.top, 6)
    }
}
