import SwiftUI
import UserNotifications

struct AddEventSheet: View {
    @ObservedObject var store: EventStore
    let selectedDate: Date
    let accent: Color
    let accent2: Color
    let surface: Color
    let surface2: Color
    let textMain: Color
    let textSub: Color

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedIcon = "📅"
    @State private var selectedColor = "#7c6af7"
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var endTime   = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    @State private var memo = ""
    @State private var notifyOn = false

    let icons = ["📅","⭐","🎂","💼","🏃","🍽️","✈️","🎮","📚","💊","🎵","🏥","🛒","💪","☕","🎨","🤝","🏠","🚗","💡"]
    let colors = ["#7c6af7", "#f76a8c", "#6abff7"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    Text("✦ 새 일정 추가")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 14)

                    // Title
                    FormSection(label: "🔤 제목") {
                        TextField("일정 제목을 입력하세요", text: $title)
                            .padding(10)
                            .background(surface2)
                            .cornerRadius(12)
                            .foregroundColor(textMain)
                    }

                    // Icon picker
                    FormSection(label: "🎯 아이콘") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Text(icon)
                                        .font(.system(size: 20))
                                        .frame(width: 42, height: 42)
                                        .background(selectedIcon == icon ? accent.opacity(0.2) : surface2)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedIcon == icon ? accent : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color picker
                    FormSection(label: "🎨 색상") {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { hex in
                                Button {
                                    selectedColor = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .purple)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle().stroke(selectedColor == hex ? textMain : Color.clear, lineWidth: 3)
                                        )
                                        .scaleEffect(selectedColor == hex ? 1.18 : 1.0)
                                        .animation(.spring(response: 0.2), value: selectedColor)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }

                    // Time
                    HStack(spacing: 10) {
                        FormSection(label: "⏰ 시작") {
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(9)
                                .background(surface2)
                                .cornerRadius(12)
                        }
                        FormSection(label: "⏱ 종료") {
                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(9)
                                .background(surface2)
                                .cornerRadius(12)
                        }
                    }

                    // Memo
                    FormSection(label: "📝 메모") {
                        TextEditor(text: $memo)
                            .frame(height: 58)
                            .padding(8)
                            .background(surface2)
                            .cornerRadius(12)
                            .foregroundColor(textMain)
                    }

                    // Notify toggle
                    HStack {
                        Text("🔔 알림 설정")
                            .font(.system(size: 13))
                            .foregroundColor(textMain)
                        Spacer()
                        Toggle("", isOn: $notifyOn)
                            .tint(Color(hex: "#1dbb8e"))
                    }
                    .padding(.vertical, 6)

                    // Save button
                    Button {
                        saveEvent()
                    } label: {
                        Text("일정 저장하기")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                LinearGradient(colors: [accent, accent2],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: accent.opacity(0.35), radius: 8, y: 4)
                    }
                    .padding(.top, 4)

                    // Cancel
                    Button("취소") { dismiss() }
                        .font(.system(size: 13))
                        .foregroundColor(textSub)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }
                .padding(18)
            }
            .background(surface.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    func saveEvent() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        let ev = CalendarEvent(
            date: store.dateKey(selectedDate),
            title: title,
            icon: selectedIcon,
            color: selectedColor,
            startTime: fmt.string(from: startTime),
            endTime: fmt.string(from: endTime),
            memo: memo,
            notify: notifyOn
        )
        store.add(ev)
        if notifyOn { scheduleNotification(for: ev) }
        dismiss()
    }

    func scheduleNotification(for ev: CalendarEvent) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "📅 곧 시작 • \(ev.title)"
            content.body  = "\(ev.startTime) 시작 예정입니다"
            content.sound = .default

            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd HH:mm"
            guard let fireDate = fmt.date(from: "\(ev.date) \(ev.startTime)"),
                  let triggerDate = Calendar.current.date(byAdding: .minute, value: -10, to: fireDate),
                  triggerDate > Date()
            else { return }

            let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: ev.id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        }
    }
}

struct FormSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#9990bb")!)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
    }
}
