// AddEventView.swift
import SwiftUI

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Form Draft (추가 폼 임시 상태 보존)

struct CalendarEventDraft {
    var title               = ""
    var date                = Date()
    var memo                = ""
    var selectedIcon        = "calendar"
    var selectedColor       = "blue"
    var notificationEnabled = false
    var showDatePicker      = false
    var showTimePicker      = false
    var reminderOption: ReminderOption = .none

    var hasContent: Bool {
        !title.isEmpty || !memo.isEmpty
    }

    mutating func reset() { self = CalendarEventDraft() }
}

// MARK: - View

struct AddEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var draft: CalendarEventDraft

    @Environment(\.dismiss) var dismiss

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월 d일 (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    private var colorForName: Color {
        switch draft.selectedColor {
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

    var body: some View {
        NavigationView {
            Form {
                // 일정 정보
                Section("일정 정보") {
                    TextField("제목을 입력하세요", text: $draft.title)
                    HStack {
                        Text("날짜")
                        Spacer()
                        Text(dateString(draft.date))
                            .foregroundStyle(.blue)
                        Image(systemName: draft.showDatePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            draft.showDatePicker.toggle()
                        }
                    }
                    if draft.showDatePicker {
                        InlineDatePicker(selection: $draft.date)
                    }
                    HStack {
                        Text("시간")
                        Spacer()
                        Text(draft.date, format: .dateTime.hour().minute())
                            .foregroundStyle(.blue)
                        Image(systemName: draft.showTimePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            draft.showTimePicker.toggle()
                        }
                    }
                    if draft.showTimePicker {
                        DatePicker("", selection: $draft.date, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }

                // 메모
                Section("메모") {
                    TextEditor(text: $draft.memo)
                        .frame(minHeight: 80)
                }

                // 아이콘 선택
                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(draft.selectedIcon == icon ? colorForName : .secondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(draft.selectedIcon == icon ? colorForName.opacity(0.15) : Color.clear)
                                )
                                .onTapGesture { draft.selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 색상 선택
                Section("색상") {
                    HStack(spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorName in
                            let color: Color = {
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
                            }()
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: draft.selectedColor == colorName ? 3 : 0)
                                )
                                .shadow(color: draft.selectedColor == colorName ? color : .clear, radius: 4)
                                .onTapGesture { draft.selectedColor = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 알림
                Section("알림") {
                    Toggle("일정 알림 받기", isOn: $draft.notificationEnabled)
                        .tint(.blue)
                        .onChange(of: draft.notificationEnabled) { enabled in
                            if enabled { draft.reminderOption = .fiveMinutes }
                        }

                    if draft.notificationEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("미리 알림")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("미리 알림", selection: $draft.reminderOption) {
                                Text("5분 전").tag(ReminderOption.fiveMinutes)
                                Text("10분 전").tag(ReminderOption.tenMinutes)
                                Text("30분 전").tag(ReminderOption.thirtyMinutes)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("새 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // 취소: 폼 초기화 후 닫기
                    Button("취소") {
                        draft.reset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        guard !draft.title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let event = Event(
                            title: draft.title,
                            date: draft.date,
                            memo: draft.memo,
                            icon: draft.selectedIcon,
                            colorName: draft.selectedColor,
                            notificationEnabled: draft.notificationEnabled,
                            reminderOption: draft.reminderOption
                        )
                        viewModel.addEvent(event)
                        draft.reset()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(false)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { UIApplication.shared.endEditing() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 커스텀 날짜 피커

private struct InlineDatePicker: View {
    @Binding var selection: Date
    @State private var displayMonth: Date

    private let cal = Calendar.current
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    init(selection: Binding<Date>) {
        _selection = selection
        _displayMonth = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button {
                    displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(.subheadline, design: .rounded).bold())
                Spacer()
                Button {
                    displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.caption2.bold())
                        .foregroundColor(i == 0 ? .red : i == 6 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { idx in
                    if let day = daysInMonth[idx] {
                        let isSelected = cal.isDate(day, inSameDayAs: selection)
                        let isToday    = cal.isDateInToday(day)
                        let weekIdx    = idx % 7

                        ZStack {
                            Circle()
                                .fill(isToday ? Color.blue : isSelected ? Color(UIColor.systemGray4) : Color.clear)
                            Text("\(cal.component(.day, from: day))")
                                .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundColor(isToday ? .white : weekIdx == 0 ? .red : weekIdx == 6 ? .blue : .primary)
                        }
                        .frame(width: 32, height: 32)
                        .onTapGesture {
                            let time = cal.dateComponents([.hour, .minute], from: selection)
                            var comps = cal.dateComponents([.year, .month, .day], from: day)
                            comps.hour   = time.hour
                            comps.minute = time.minute
                            if let newDate = cal.date(from: comps) { selection = newDate }
                        }
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: displayMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range    = cal.range(of: .day, in: .month, for: displayMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        let offset = cal.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: offset)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: firstDay) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}
