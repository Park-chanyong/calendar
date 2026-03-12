// MonthView.swift
import SwiftUI

struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false

    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    // 화면 높이의 58%를 달력 영역으로 사용, 헤더(~62pt) + 행 간격(5×4pt) 제외
    private var cellHeight: CGFloat {
        max(44, (UIScreen.main.bounds.height * 0.58 - 82) / 6)
    }

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
                            weekdayIndex: idx % 7,
                            cellHeight: cellHeight
                        )
                        .onTapGesture { viewModel.selectedDate = date }
                    } else {
                        Color.clear.frame(height: cellHeight)
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
                        let px = value.predictedEndTranslation.width
                        let threshold = UIScreen.main.bounds.width / 7 * 0.5
                        if abs(dx) > abs(value.translation.height) {
                            // 빠른 플릭도 감지하기 위해 예측 이동량 사용
                            let effective = abs(px) > threshold && px * dx > 0 ? px : dx
                            if effective < -threshold { switchMonth(direction: 1) }
                            else if effective > threshold { switchMonth(direction: -1) }
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
        withAnimation(.easeIn(duration: 0.15), completionCriteria: .removed) {
            dragOffset = out
        } completion: {
            if direction > 0 { viewModel.nextMonth() } else { viewModel.previousMonth() }
            dragOffset = inn
            withAnimation(.spring(response: 0.32, dampingFraction: 0.9), completionCriteria: .removed) {
                dragOffset = 0
            } completion: {
                isAnimating = false
            }
        }
    }
}

#Preview {
    MonthView(viewModel: CalendarViewModel())
}

struct MonthDayCell: View {
    let date: Date; let isSelected: Bool; let isToday: Bool
    let events: [Event]; let weekdayIndex: Int
    let cellHeight: CGFloat

    private var holiday: String? { HolidayManager.holiday(for: date) }
    private var dayNum: Int { Calendar.current.component(.day, from: date) }
    private var isRed: Bool { holiday != nil || weekdayIndex == 0 }

    private var circleFill: Color {
        if isToday    { return .blue }
        if isSelected { return Color(UIColor.systemGray4) }
        return .clear
    }

    private var numberColor: Color {
        if isToday    { return .white }
        if isSelected { return .primary }
        if isRed      { return .red }
        if weekdayIndex == 6 { return .blue }
        return .primary
    }

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle().fill(circleFill)
                Text("\(dayNum)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(numberColor)
            }
            .frame(width: 28, height: 28)

            if let hol = holiday {
                Text(hol)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .red)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity).padding(.horizontal, 1)
            }

            HStack(spacing: 2) {
                ForEach(Array(events.prefix(3))) { event in
                    Circle().fill(event.color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity)
        .frame(height: cellHeight, alignment: .top)
    }
}
