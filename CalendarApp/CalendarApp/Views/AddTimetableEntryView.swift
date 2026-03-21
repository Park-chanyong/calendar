// AddTimetableEntryView.swift
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

struct AddTimetableEntryView: View {
    @ObservedObject var vm: TimetableViewModel
    let entry: TimetableEntry?
    @Binding var draft: TimetableFormDraft

    @Environment(\.dismiss) private var dismiss

    private let weekdays = ["월", "화", "수", "목", "금"]
    private var isEditing: Bool { entry != nil }

    private let availableIcons: [String] = [
        "book.fill", "pencil", "function", "sum",
        "textformat", "number", "atom", "flask.fill",
        "leaf.fill", "globe", "music.note", "paintpalette.fill",
        "sportscourt.fill", "dumbbell.fill", "figure.run", "theatermasks.fill",
        "desktopcomputer", "keyboard", "cpu", "network",
        "map.fill", "building.columns.fill", "person.2.fill", "heart.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                // 기본 정보
                Section("기본 정보") {
                    TextField("제목을 입력하세요", text: $draft.title)

                    if isEditing {
                        // 수정 모드: 단일 요일 Picker
                        Picker("요일", selection: $draft.weekday) {
                            ForEach(1..<6, id: \.self) { i in
                                Text(weekdays[i - 1]).tag(i)
                            }
                        }
                    } else {
                        // 추가 모드: 다중 요일 선택
                        VStack(alignment: .leading, spacing: 8) {
                            Text("요일")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                ForEach(1..<6, id: \.self) { i in
                                    let isSelected = draft.selectedWeekdays.contains(i)
                                    Button {
                                        if isSelected {
                                            draft.selectedWeekdays.remove(i)
                                        } else {
                                            draft.selectedWeekdays.insert(i)
                                        }
                                    } label: {
                                        Text(weekdays[i - 1])
                                            .font(.system(size: 14, weight: .semibold))
                                            .frame(width: 36, height: 36)
                                            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                        TextField("강의실 (예: 공학관 401호)", text: $draft.location)
                    }

                    DatePicker("시작 시간", selection: $draft.startTime, in: allowedTimeRange, displayedComponents: [.hourAndMinute])
                    DatePicker("종료 시간", selection: $draft.endTime,   in: allowedTimeRange, displayedComponents: [.hourAndMinute])
                }

                // 중요 표시
                Section {
                    Toggle(isOn: $draft.isImportant) {
                        HStack(spacing: 8) {
                            Image(systemName: draft.isImportant ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                            Text("중요 과목")
                        }
                    }
                    .tint(.yellow)
                }

                // 메모
                Section("메모") {
                    TextEditor(text: $draft.memo)
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
                                    Circle().stroke(Color.white, lineWidth: draft.selectedColor == colorName ? 3 : 0)
                                )
                                .shadow(color: draft.selectedColor == colorName ? color : .clear, radius: 4)
                                .onTapGesture { draft.selectedColor = colorName }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 아이콘
                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        Button { draft.selectedIcon = "" } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(draft.selectedIcon.isEmpty ? Color.blue : Color(UIColor.systemGray5))
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(draft.selectedIcon.isEmpty ? .white : .secondary)
                            }
                            .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)

                        ForEach(availableIcons, id: \.self) { icon in
                            Button { draft.selectedIcon = icon } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(draft.selectedIcon == icon ? Color.blue : Color(UIColor.systemGray5))
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(draft.selectedIcon == icon ? .white : .primary)
                                }
                                .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // 삭제 (수정 모드)
                if isEditing {
                    Section {
                        Button("삭제", role: .destructive) {
                            if let e = entry { vm.delete(id: e.id) }
                            draft.reset()
                            dismiss()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(KeyboardDismissView().frame(width: 0, height: 0))
            .navigationTitle(isEditing ? "시간표 수정" : "시간표 추가")
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
                    Button("저장") { save() }
                        .fontWeight(.semibold)
                        .disabled(false)
                }
            }
        }
        // 수정 모드: 시트가 열릴 때 entry 데이터로 draft 채우기
        .onAppear {
            if let e = entry {
                draft = TimetableFormDraft(from: e)
            }
        }
    }

    private var allowedTimeRange: ClosedRange<Date> {
        let cal = Calendar.current
        let min = cal.date(bySettingHour: 9,  minute: 0, second: 0, of: Date())!
        let max = cal.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        return min...max
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
        let startComps = cal.dateComponents([.hour, .minute], from: draft.startTime)
        let endComps   = cal.dateComponents([.hour, .minute], from: draft.endTime)

        if let e = entry {
            var updated = TimetableEntry(
                title:       draft.title.trimmingCharacters(in: .whitespaces),
                weekday:     draft.weekday,
                startHour:   startComps.hour   ?? 0,
                startMinute: startComps.minute ?? 0,
                endHour:     endComps.hour     ?? 0,
                endMinute:   endComps.minute   ?? 0,
                colorName:   draft.selectedColor,
                iconName:    draft.selectedIcon,
                location:    draft.location,
                memo:        draft.memo,
                isImportant: draft.isImportant
            )
            updated.id = e.id
            vm.update(updated)
        } else {
            for day in draft.selectedWeekdays.sorted() {
                let newEntry = TimetableEntry(
                    title:       draft.title.trimmingCharacters(in: .whitespaces),
                    weekday:     day,
                    startHour:   startComps.hour   ?? 0,
                    startMinute: startComps.minute ?? 0,
                    endHour:     endComps.hour     ?? 0,
                    endMinute:   endComps.minute   ?? 0,
                    colorName:   draft.selectedColor,
                    iconName:    draft.selectedIcon,
                    location:    draft.location,
                    memo:        draft.memo,
                    isImportant: draft.isImportant
                )
                vm.add(newEntry)
            }
        }
        draft.reset()
        dismiss()
    }
}
