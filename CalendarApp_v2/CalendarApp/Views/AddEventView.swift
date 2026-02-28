// AddEventView.swift
import SwiftUI

private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) var dismiss
    
    var selectedDate: Date
    
    @State private var title = ""
    @State private var date: Date
    @State private var memo = ""
    @State private var selectedIcon = "calendar"
    @State private var selectedColor = "blue"
    @State private var notificationEnabled = false
    @State private var showTimePicker = false
    @State private var reminderOption: ReminderOption = .none
    
    init(viewModel: CalendarViewModel, selectedDate: Date) {
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        _date = State(initialValue: selectedDate)
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
        NavigationView {
            Form {
                // 기본 정보
                Section("일정 정보") {
                    TextField("제목을 입력하세요", text: $title)
                    DatePicker("날짜", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                    HStack {
                        Text("시간")
                        Spacer()
                        Text(date, format: .dateTime.hour().minute())
                            .foregroundStyle(.blue)
                        Image(systemName: showTimePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTimePicker.toggle()
                        }
                    }
                    if showTimePicker {
                        DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 메모
                Section("메모") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                }
                
                // 아이콘 선택
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
                                .onTapGesture {
                                    selectedIcon = icon
                                }
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
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == colorName ? 3 : 0)
                                )
                                .shadow(color: selectedColor == colorName ? color : .clear, radius: 4)
                                .onTapGesture {
                                    selectedColor = colorName
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 알림
                Section("알림") {
                    Toggle("일정 알림 받기", isOn: $notificationEnabled)
                        .tint(.blue)
                        .onChange(of: notificationEnabled) { enabled in
                            if enabled { reminderOption = .fiveMinutes }
                        }

                    if notificationEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("미리 알림")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("미리 알림", selection: $reminderOption) {
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
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.endEditing()
            })
            .navigationTitle("새 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let event = Event(
                            title: title,
                            date: date,
                            memo: memo,
                            icon: selectedIcon,
                            colorName: selectedColor,
                            notificationEnabled: notificationEnabled,
                            reminderOption: reminderOption
                        )
                        viewModel.addEvent(event)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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

#Preview {
    AddEventView(viewModel: CalendarViewModel(), selectedDate: Date())
}
