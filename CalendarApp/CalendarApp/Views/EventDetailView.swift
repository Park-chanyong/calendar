// EventDetailView.swift
import SwiftUI

struct EventDetailView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var event: Event
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    
    var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        switch event.category {
        case .assignment:
            f.dateFormat = "yyyy년 M월 d일 (E) HH:mm 마감"
            return f.string(from: event.date)
        case .exam:
            f.dateFormat = "yyyy년 M월 d일 (E)"
            let day = f.string(from: event.date)
            let tf = DateFormatter()
            tf.dateFormat = "HH:mm"
            let start = tf.string(from: event.date)
            let end   = event.endDate.map { tf.string(from: $0) } ?? ""
            return end.isEmpty ? "\(day) \(start)" : "\(day)  \(start) ~ \(end)"
        case .general:
            f.dateFormat = "yyyy년 M월 d일 (E) HH:mm"
            return f.string(from: event.date)
        }
    }
    
    var body: some View {
        NavigationView {
            if isEditing {
                EditEventView(viewModel: viewModel, event: $event, isEditing: $isEditing)
            } else {
                // 상세 보기
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 헤더
                        HStack(spacing: 16) {
                            Image(systemName: event.icon)
                                .font(.largeTitle)
                                .foregroundColor(event.color)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(event.color.opacity(0.15))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    if event.category != .general {
                                        Label(event.category.label, systemImage: event.category.sfSymbol)
                                            .font(.caption.bold())
                                            .foregroundColor(event.category.badgeColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(event.category.badgeColor.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(event.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(dateString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Divider()

                        // 과목 (시험/과제)
                        if event.category != .general && !event.subjectName.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("과목", systemImage: event.category.sfSymbol)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(event.subjectName)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        // 장소
                        if !event.location.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("장소", systemImage: "mappin.and.ellipse")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(event.location)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }

                        // 메모
                        if !event.memo.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("메모", systemImage: "note.text")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(event.memo)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // 알림
                        VStack(alignment: .leading, spacing: 8) {
                            Label("알림", systemImage: "bell.fill")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: event.notificationEnabled ? "bell.fill" : "bell.slash.fill")
                                    .foregroundColor(event.notificationEnabled ? .orange : .secondary)
                                Text(event.notificationEnabled ? "알림 설정됨" : "알림 없음")
                                    .foregroundColor(event.notificationEnabled ? .primary : .secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // 삭제 버튼
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("일정 삭제", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .padding(.bottom)
                }
                .navigationTitle("일정 상세")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("닫기") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("편집") { isEditing = true }
                    }
                }
                .alert("일정 삭제", isPresented: $showDeleteAlert) {
                    Button("삭제", role: .destructive) {
                        viewModel.deleteEvent(event)
                        dismiss()
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("'\(event.title)' 일정을 삭제할까요?")
                }
            }
        }
    }
}

#Preview {
    let event = Event(title: "팀 미팅", date: Date(), memo: "주간 업무 공유", icon: "person.fill", colorName: "blue", notificationEnabled: true)
    EventDetailView(viewModel: CalendarViewModel(), event: event)
}

struct EditEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var event: Event
    @Binding var isEditing: Bool
    
    @State private var title: String
    @State private var date: Date
    @State private var location: String
    @State private var memo: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var category: EventCategory
    @State private var subjectName: String
    @State private var endDate: Date
    @State private var notificationEnabled: Bool
    @State private var reminderOption: ReminderOption

    init(viewModel: CalendarViewModel, event: Binding<Event>, isEditing: Binding<Bool>) {
        self.viewModel = viewModel
        _event = event
        _isEditing = isEditing
        _title = State(initialValue: event.wrappedValue.title)
        _date = State(initialValue: event.wrappedValue.date)
        _location = State(initialValue: event.wrappedValue.location)
        _memo = State(initialValue: event.wrappedValue.memo)
        _selectedIcon = State(initialValue: event.wrappedValue.icon)
        _selectedColor = State(initialValue: event.wrappedValue.colorName)
        _category = State(initialValue: event.wrappedValue.category)
        _subjectName = State(initialValue: event.wrappedValue.subjectName)
        _endDate = State(initialValue: event.wrappedValue.endDate ?? event.wrappedValue.date.addingTimeInterval(7200))
        _notificationEnabled = State(initialValue: event.wrappedValue.notificationEnabled)
        _reminderOption = State(initialValue: event.wrappedValue.reminderOption)
    }
    
    var colorForName: Color {
        switch selectedColor {
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
        Form {
            Section("일정 정보") {
                Picker("분류", selection: $category) {
                    ForEach(EventCategory.allCases, id: \.self) { cat in
                        Label(cat.label, systemImage: cat.sfSymbol).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: category) { _ in subjectName = "" }

                // 시험/과제: 시간표 과목 선택
                if category == .exam || category == .assignment {
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
                        Picker("과목", selection: $subjectName) {
                            Text("과목 선택").tag("")
                            ForEach(subjects, id: \.self) { subject in
                                Text(subject).tag(subject)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                TextField("제목", text: $title)
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("장소 (선택)", text: $location)
                }

                let startLabel = category == .assignment ? "마감 날짜 및 시간"
                               : category == .exam       ? "시작 날짜 및 시간" : "날짜 및 시간"
                DatePicker(startLabel, selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ko_KR"))

                if category == .exam {
                    DatePicker("종료 날짜 및 시간", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                        .foregroundStyle(.red)
                }
            }

            Section("메모") {
                TextEditor(text: $memo)
                    .frame(minHeight: 80)
            }
            
            Section("아이콘") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(selectedIcon == icon ? colorForName : .secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? colorForName.opacity(0.15) : Color.clear)
                            )
                            .onTapGesture { selectedIcon = icon }
                    }
                }
                .padding(.vertical, 4)
            }
            
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
                            .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == colorName ? 3 : 0))
                            .shadow(color: selectedColor == colorName ? color : .clear, radius: 4)
                            .onTapGesture { selectedColor = colorName }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("알림") {
                Toggle("일정 알림 받기", isOn: $notificationEnabled)
                    .tint(.blue)
                
                if notificationEnabled {
                    Picker("미리 알림", selection: $reminderOption) {
                        ForEach(ReminderOption.allCases.filter { $0 != .none }, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .navigationTitle("일정 편집")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("취소") { isEditing = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    event.title = title
                    event.date = date
                    event.location = location
                    event.memo = memo
                    event.icon = selectedIcon
                    event.colorName = selectedColor
                    event.category = category
                    event.subjectName = subjectName
                    event.endDate = category == .exam ? endDate : nil
                    event.notificationEnabled = notificationEnabled
                    event.reminderOption = reminderOption
                    viewModel.updateEvent(event)
                    isEditing = false
                }
                .fontWeight(.semibold)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
