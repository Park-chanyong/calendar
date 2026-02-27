// EventDetailView.swift
import SwiftUI

struct EventDetailView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var event: Event
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E) HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: event.date)
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

struct EditEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var event: Event
    @Binding var isEditing: Bool
    
    @State private var title: String
    @State private var date: Date
    @State private var memo: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var notificationEnabled: Bool
    @State private var reminderOption: ReminderOption
    
    init(viewModel: CalendarViewModel, event: Binding<Event>, isEditing: Binding<Bool>) {
        self.viewModel = viewModel
        _event = event
        _isEditing = isEditing
        _title = State(initialValue: event.wrappedValue.title)
        _date = State(initialValue: event.wrappedValue.date)
        _memo = State(initialValue: event.wrappedValue.memo)
        _selectedIcon = State(initialValue: event.wrappedValue.icon)
        _selectedColor = State(initialValue: event.wrappedValue.colorName)
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
                TextField("제목", text: $title)
                DatePicker("날짜 및 시간", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "ko_KR"))
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
                        ForEach(ReminderOption.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
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
                    event.memo = memo
                    event.icon = selectedIcon
                    event.colorName = selectedColor
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
