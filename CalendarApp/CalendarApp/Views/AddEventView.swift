// AddEventView.swift
import SwiftUI

private struct KeyboardDismissView: UIViewRepresentable {
    final class TapView: UIView {
        private var tapGesture: UITapGestureRecognizer?
        private weak var targetWindow: UIWindow?

        @objc private func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let tap = tapGesture {
                targetWindow?.removeGestureRecognizer(tap)
                tapGesture = nil
                targetWindow = nil
            }
            guard let window else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            window.addGestureRecognizer(tap)
            tapGesture = tap
            targetWindow = window
        }
    }
    func makeUIView(context: Context) -> TapView { TapView() }
    func updateUIView(_ uiView: TapView, context: Context) {}
}

// MARK: - Form Draft (추가 폼 임시 상태 보존)

struct CalendarEventDraft {
    var title               = ""
    var date                = Date()
    var location            = ""
    var memo                = ""
    var selectedIcon        = "calendar"
    var selectedColor       = "blue"
    var category: EventCategory     = .general
    var subjectName: String         = ""
    var endDate: Date               = Date().addingTimeInterval(7200)  // 시험 종료 시간 (기본 2시간 후)
    var notificationEnabled = false
    var showDatePicker      = false
    var showTimePicker      = false
    var showEndDatePicker   = false
    var showEndTimePicker   = false
    var reminderOption: ReminderOption = .none

    var hasContent: Bool {
        !title.isEmpty || !location.isEmpty || !memo.isEmpty
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
                    // 카테고리 선택
                    Picker("분류", selection: $draft.category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.sfSymbol).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: draft.category) { _ in
                        draft.subjectName = ""
                    }

                    // 시험/과제: 시간표 과목 선택
                    if draft.category == .exam || draft.category == .assignment {
                        let subjects = viewModel.subjectTitles
                        if subjects.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("시간표에 등록된 과목이 없습니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Picker("과목", selection: $draft.subjectName) {
                                Text("과목 선택").tag("")
                                ForEach(subjects, id: \.self) { subject in
                                    Text(subject).tag(subject)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    TextField("제목을 입력하세요", text: $draft.title)
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("장소 (선택)", text: $draft.location)
                    }

                    // 시작 날짜 (과제: 마감 날짜 / 시험: 시작 날짜 / 일반: 날짜)
                    let startDateLabel = draft.category == .assignment ? "마감 날짜"
                                      : draft.category == .exam       ? "시작 날짜" : "날짜"
                    let startTimeLabel = draft.category == .assignment ? "마감 시간"
                                      : draft.category == .exam       ? "시작 시간" : "시간"
                    HStack {
                        Text(startDateLabel)
                        Spacer()
                        Text(dateString(draft.date)).foregroundStyle(.blue)
                        Image(systemName: draft.showDatePicker ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { draft.showDatePicker.toggle() }
                    }
                    if draft.showDatePicker { InlineDatePicker(selection: $draft.date) }

                    HStack {
                        Text(startTimeLabel)
                        Spacer()
                        Text(draft.date, format: .dateTime.hour().minute()).foregroundStyle(.blue)
                        Image(systemName: draft.showTimePicker ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { draft.showTimePicker.toggle() }
                    }
                    if draft.showTimePicker {
                        DatePicker("", selection: $draft.date, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity)
                    }

                    // 시험: 종료 날짜/시간
                    if draft.category == .exam {
                        HStack {
                            Text("종료 날짜")
                            Spacer()
                            Text(dateString(draft.endDate)).foregroundStyle(.red)
                            Image(systemName: draft.showEndDatePicker ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { draft.showEndDatePicker.toggle() }
                        }
                        if draft.showEndDatePicker { InlineDatePicker(selection: $draft.endDate) }

                        HStack {
                            Text("종료 시간")
                            Spacer()
                            Text(draft.endDate, format: .dateTime.hour().minute()).foregroundStyle(.red)
                            Image(systemName: draft.showEndTimePicker ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { draft.showEndTimePicker.toggle() }
                        }
                        if draft.showEndTimePicker {
                            DatePicker("", selection: $draft.endDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity)
                        }
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
                            if enabled { draft.reminderOption = .tenMinutes }
                        }

                    if draft.notificationEnabled {
                        Picker("미리 알림", selection: $draft.reminderOption) {
                            ForEach(ReminderOption.allCases.filter { $0 != .none }, id: \.self) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(KeyboardDismissView().frame(width: 0, height: 0))
            .onAppear { viewModel.loadTimetableEntries() }
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
                            location: draft.location,
                            memo: draft.memo,
                            icon: draft.selectedIcon,
                            colorName: draft.selectedColor,
                            category: draft.category,
                            subjectName: draft.subjectName,
                            endDate: draft.category == .exam ? draft.endDate : nil,
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
