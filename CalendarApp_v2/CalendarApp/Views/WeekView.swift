// WeekView.swift
import SwiftUI

struct WeekView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { switchWeek(direction: -1) } label: {
                    Image(systemName: "chevron.left").foregroundColor(.blue)
                }
                Spacer()
                Text(viewModel.weekTitle(for: viewModel.selectedDate))
                    .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                    .minimumScaleFactor(0.7)
                Spacer()
                Button { switchWeek(direction: 1) } label: {
                    Image(systemName: "chevron.right").foregroundColor(.blue)
                }
            }
            .padding(.horizontal).padding(.vertical, 8)

            Divider()

            HStack(spacing: 0) {
                ForEach(Array(viewModel.daysInWeek(for: viewModel.selectedDate).enumerated()), id: \.offset) { i, date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                    let isToday    = Calendar.current.isDateInToday(date)
                    let holiday    = HolidayManager.holiday(for: date)
                    let hasEvents  = !viewModel.events(for: date).isEmpty
                    let isRed      = holiday != nil || i == 0
                    let dayNum     = Calendar.current.component(.day, from: date)

                    let textColor: Color = {
                        if isSelected { return .white }
                        if isToday    { return .blue  }
                        if isRed      { return .red   }
                        if i == 6     { return .blue  }
                        return .primary
                    }()

                    VStack(spacing: 2) {
                        Text(["일","월","화","수","목","금","토"][i])
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(isRed ? .red : i == 6 ? .blue : .secondary)

                        Text("\(dayNum)")
                            .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                            .foregroundColor(textColor)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(
                                isSelected ? Color.blue :
                                isToday    ? Color.blue.opacity(0.15) :
                                Color.clear
                            ))

                        if let hol = holiday {
                            Text(hol)
                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white.opacity(0.85) : .red)
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity).padding(.horizontal, 2)
                        }

                        Circle()
                            .fill(hasEvents ? Color.blue : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture { viewModel.selectedDate = date }
                }
            }
            .padding(.vertical, 8)
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
                            if dx < -50 { switchWeek(direction: 1) }
                            else if dx > 50 { switchWeek(direction: -1) }
                            else { withAnimation(.spring(response: 0.3)) { dragOffset = 0 } }
                        } else {
                            withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                        }
                    }
            )
            .clipped()

            Divider()
        }
    }

    private func switchWeek(direction: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        let w = UIScreen.main.bounds.width
        let out: CGFloat = direction > 0 ? -w : w
        let inn: CGFloat = direction > 0 ?  w : -w
        withAnimation(.easeInOut(duration: 0.38)) { dragOffset = out }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            if direction > 0 { viewModel.nextWeek() } else { viewModel.previousWeek() }
            dragOffset = inn
            withAnimation(.easeInOut(duration: 0.38)) { dragOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { isAnimating = false }
        }
    }
}

#Preview {
    WeekView(viewModel: CalendarViewModel())
}
