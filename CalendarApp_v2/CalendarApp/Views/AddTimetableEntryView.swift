// AddTimetableEntryView.swift
import SwiftUI

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddTimetableEntryView: View {
    @ObservedObject var vm: TimetableViewModel
    let entry: TimetableEntry?

    @Environment(\.dismiss) private var dismiss

    @State private var title         = ""
    @State private var weekday       = 1   // 1=월 ~ 5=금
    @State private var startTime: Date
    @State private var endTime:   Date
    @State private var selectedColor = "blue"
    @State private var memo          = ""
    @State private var isImportant   = false

    private let weekdays = ["월", "화", "수", "목", "금"]
    private var isEditing: Bool { entry != nil }

    init(vm: TimetableViewModel, entry: TimetableEntry?) {
        self.vm    = vm
        self.entry = entry

        let cal = Calendar.current
        if let e = entry {
            _title         = State(initialValue: e.title)
            _weekday       = State(initialValue: max(1, min(5, e.weekday)))
            _selectedColor = State(initialValue: e.colorName)
            _memo          = State(initialValue: e.memo)
            _isImportant   = State(initialValue: e.isImportant)
            _startTime     = State(initialValue:
                cal.date(bySettingHour: e.startHour, minute: e.startMinute, second: 0, of: Date()) ?? Date())
            _endTime       = State(initialValue:
                cal.date(bySettingHour: e.endHour,   minute: e.endMinute,   second: 0, of: Date()) ?? Date())
        } else {
            _startTime = State(initialValue:
                cal.date(bySettingHour: 9,  minute: 0, second: 0, of: Date()) ?? Date())
            _endTime   = State(initialValue:
                cal.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date())
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // 기본 정보
                Section("기본 정보") {
                    TextField("제목을 입력하세요", text: $title)

                    Picker("요일", selection: $weekday) {
                        ForEach(1..<6, id: \.self) { i in
                            Text(weekdays[i - 1]).tag(i)
                        }
                    }

                    DatePicker("시작 시간", selection: $startTime, displayedComponents: [.hourAndMinute])
                    DatePicker("종료 시간", selection: $endTime,   displayedComponents: [.hourAndMinute])
                }

                // 중요 표시
                Section {
                    Toggle(isOn: $isImportant) {
                        HStack(spacing: 8) {
                            Image(systemName: isImportant ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                            Text("중요 과목")
                        }
                    }
                    .tint(.yellow)
                }

                // 메모
                Section("메모") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 60)
                }

                // 색상
                Section("색상") {
                    HStack(spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorName in
                            let color = colorFor(colorName)
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColor == colorName ? 3 : 0)
                                )
                                .shadow(color: selectedColor == colorName ? color : .clear, radius: 4)
                                .onTapGesture { selectedColor = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 삭제 (수정 모드)
                if isEditing {
                    Section {
                        Button("삭제", role: .destructive) {
                            if let e = entry { vm.delete(id: e.id) }
                            dismiss()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(isEditing ? "시간표 수정" : "시간표 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                // 키보드 위 완료 버튼
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { UIApplication.shared.endEditing() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
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

    private func save() {
        let cal        = Calendar.current
        let startComps = cal.dateComponents([.hour, .minute], from: startTime)
        let endComps   = cal.dateComponents([.hour, .minute], from: endTime)

        var newEntry = TimetableEntry(
            title:       title.trimmingCharacters(in: .whitespaces),
            weekday:     weekday,
            startHour:   startComps.hour   ?? 0,
            startMinute: startComps.minute ?? 0,
            endHour:     endComps.hour     ?? 0,
            endMinute:   endComps.minute   ?? 0,
            colorName:   selectedColor,
            memo:        memo,
            isImportant: isImportant
        )
        if let e = entry {
            newEntry.id = e.id
            vm.update(newEntry)
        } else {
            vm.add(newEntry)
        }
        dismiss()
    }
}
