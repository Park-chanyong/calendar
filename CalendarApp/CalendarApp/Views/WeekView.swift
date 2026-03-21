// WeekView.swift
import SwiftUI

struct WeekView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var viewWidth: CGFloat = 390

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

                    let circleFill: Color = {
                        if isToday    { return .blue }
                        if isSelected { return Color(UIColor.systemGray4) }
                        return .clear
                    }()

                    let numberColor: Color = {
                        if isToday    { return .white }
                        if isSelected { return .primary }
                        if isRed      { return .red }
                        if i == 6     { return .blue }
                        return .primary
                    }()

                    VStack(spacing: 2) {
                        Text(["일","월","화","수","목","금","토"][i])
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(isRed ? .red : i == 6 ? .blue : .secondary)

                        ZStack {
                            Circle().fill(circleFill)
                            Text("\(dayNum)")
                                .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundColor(numberColor)
                        }
                        .frame(width: 34, height: 34)

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
                            dragOffset = value.translation.width * 0.5
                        }
                    }
                    .onEnded { value in
                        guard !isAnimating else { return }
                        let dx = value.translation.width
                        let px = value.predictedEndTranslation.width
                        let threshold = viewWidth / 7 * 0.5
                        if abs(dx) > abs(value.translation.height) {
                            // 빠른 플릭도 감지하기 위해 예측 이동량 사용
                            let effective = abs(px) > threshold && px * dx > 0 ? px : dx
                            if effective < -threshold { switchWeek(direction: 1) }
                            else if effective > threshold { switchWeek(direction: -1) }
                            else { withAnimation(.spring(response: 0.3)) { dragOffset = 0 } }
                        } else {
                            withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                        }
                    }
            )
            .clipped()

            Divider()
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { viewWidth = geo.size.width }
                    .onChange(of: geo.size.width) { viewWidth = $0 }
            }
        )
    }

    private func switchWeek(direction: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        let w = viewWidth
        let out: CGFloat = direction > 0 ? -w : w
        let inn: CGFloat = direction > 0 ?  w : -w
        withAnimation(.easeIn(duration: 0.18), completionCriteria: .removed) {
            dragOffset = out
        } completion: {
            if direction > 0 { viewModel.nextWeek() } else { viewModel.previousWeek() }
            dragOffset = inn
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9), completionCriteria: .removed) {
                dragOffset = 0
            } completion: {
                isAnimating = false
            }
        }
    }
}

#Preview {
    WeekView(viewModel: CalendarViewModel())
}
