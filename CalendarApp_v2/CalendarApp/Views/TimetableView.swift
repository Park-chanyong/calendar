// TimetableView.swift
import SwiftUI
import WidgetKit

// MARK: - ViewModel

class TimetableViewModel: ObservableObject {
    @Published var entries: [TimetableEntry] = []

    private let saveKey    = "TimetableEntries"
    private let appGroupID = "group.com.example3.CalendarApp"
    private var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    init() { load() }

    func add(_ entry: TimetableEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: TimetableEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func entries(for weekday: Int) -> [TimetableEntry] {
        entries.filter { $0.weekday == weekday }
            .sorted { $0.startTotalMinutes < $1.startTotalMinutes }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: saveKey)
            defaults.synchronize()
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "TimetableWidget")
    }

    private func load() {
        guard let data    = defaults.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([TimetableEntry].self, from: data)
        else { return }
        entries = decoded
    }
}

// MARK: - Form Draft (추가/수정 폼 임시 상태 보존)

struct TimetableFormDraft {
    var title            = ""
    var weekday          = 1         // 수정 모드 단일 요일
    var selectedWeekdays: Set<Int> = []  // 추가 모드 다중 요일
    var startTime: Date
    var endTime:   Date
    var selectedColor    = "blue"
    var selectedIcon     = ""
    var location         = ""
    var memo             = ""
    var isImportant      = false

    init() {
        let cal = Calendar.current
        startTime = cal.date(bySettingHour: 9,  minute: 0, second: 0, of: Date()) ?? Date()
        endTime   = cal.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    }

    init(from entry: TimetableEntry) {
        let cal = Calendar.current
        title          = entry.title
        weekday        = max(1, min(5, entry.weekday))
        selectedWeekdays = [max(1, min(5, entry.weekday))]
        selectedColor  = entry.colorName
        selectedIcon   = entry.iconName
        location       = entry.location
        memo           = entry.memo
        isImportant    = entry.isImportant
        startTime = cal.date(bySettingHour: entry.startHour, minute: entry.startMinute, second: 0, of: Date()) ?? Date()
        endTime   = cal.date(bySettingHour: entry.endHour,   minute: entry.endMinute,   second: 0, of: Date()) ?? Date()
    }

    var hasContent: Bool {
        !title.isEmpty || !location.isEmpty || !memo.isEmpty || !selectedWeekdays.isEmpty
    }

    mutating func reset() { self = TimetableFormDraft() }
}

// MARK: - View

struct TimetableView: View {
    @StateObject private var vm = TimetableViewModel()
    @State private var showAddEntry  = false
    @State private var editingEntry: TimetableEntry? = nil
    @State private var addDraft  = TimetableFormDraft()   // 추가 폼 임시 저장
    @State private var editDraft = TimetableFormDraft()   // 수정 폼 임시 저장

    private let hourHeight:    CGFloat = 60
    private let timeAxisWidth: CGFloat = 44
    private let startHour = 9
    private let endHour   = 18
    private let weekdays = ["월", "화", "수", "목", "금"]

    private var columnWidth: CGFloat {
        (UIScreen.main.bounds.width - timeAxisWidth) / 5
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 요일 헤더 (월~금)
                HStack(spacing: 0) {
                    Spacer().frame(width: timeAxisWidth)
                    ForEach(0..<5, id: \.self) { i in
                        // Calendar.weekday: 1=일,2=월,...,6=금 → i=0=월 → weekday=2
                        let isToday = Calendar.current.component(.weekday, from: Date()) - 2 == i
                        Text(weekdays[i])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isToday ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)

                Divider()

                // 시간 그리드 (09:00 ~ 18:00 포함, 월~금)
                let totalHours = endHour - startHour          // 9 (블록 위치 계산용)
                let displayRows = totalHours + 1              // 10 (라벨: 09~18 포함)
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // 시간 레이블 + 가로 구분선 (09:00 ~ 18:00)
                        VStack(spacing: 0) {
                            ForEach(startHour...endHour, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(String(format: "%02d:00", hour))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: timeAxisWidth - 4, alignment: .trailing)
                                    VStack(spacing: 0) {
                                        Divider()
                                        Spacer()
                                    }
                                }
                                .frame(height: hourHeight)
                            }
                        }

                        // 세로 열 구분선 (월~금)
                        HStack(spacing: 0) {
                            Spacer().frame(width: timeAxisWidth)
                            ForEach(0..<5, id: \.self) { i in
                                Spacer().frame(maxWidth: .infinity)
                                if i < 4 { Divider() }
                            }
                        }
                        .frame(height: hourHeight * CGFloat(displayRows))

                        // 각 요일의 고정 시간표 블록 (월=1 ~ 금=5)
                        ForEach(0..<5, id: \.self) { colIdx in
                            ForEach(vm.entries(for: colIdx + 1)) { entry in
                                TimetableBlock(
                                    entry: entry,
                                    width: columnWidth - 2,
                                    hourHeight: hourHeight
                                )
                                .offset(
                                    x: timeAxisWidth + CGFloat(colIdx) * columnWidth + 1,
                                    y: CGFloat(entry.startHour - startHour) * hourHeight + CGFloat(entry.startMinute)
                                )
                                .onTapGesture { editingEntry = entry }
                            }
                        }
                    }
                    .frame(height: hourHeight * CGFloat(displayRows))
                }
            }
            .navigationTitle("시간표")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddTimetableEntryView(vm: vm, entry: nil, draft: $addDraft)
            }
            .sheet(item: $editingEntry) { entry in
                AddTimetableEntryView(vm: vm, entry: entry, draft: $editDraft)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if addDraft.hasContent && !showAddEntry {
                DraftResumeBanner(
                    title: addDraft.title,
                    placeholder: "작성 중인 시간표"
                ) {
                    showAddEntry = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: addDraft.hasContent)
    }

}

// MARK: - 시간표 블록

struct TimetableBlock: View {
    let entry:      TimetableEntry
    let width:      CGFloat
    let hourHeight: CGFloat

    private var blockHeight: CGFloat {
        max(30, CGFloat(entry.durationMinutes) * hourHeight / 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                if entry.isImportant {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
                if !entry.iconName.isEmpty {
                    Image(systemName: entry.iconName)
                        .font(.system(size: 9))
                        .foregroundColor(entry.color)
                }
                Text(entry.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(entry.color)
                    .lineLimit(2)
            }
            if entry.durationMinutes >= 45 {
                Text(String(format: "%02d:%02d–%02d:%02d",
                            entry.startHour, entry.startMinute,
                            entry.endHour,   entry.endMinute))
                    .font(.system(size: 9))
                    .foregroundColor(entry.color.opacity(0.8))
                    .lineLimit(1)
            }
            if !entry.location.isEmpty && entry.durationMinutes >= 60 {
                HStack(spacing: 2) {
                    Image(systemName: "mappin")
                        .font(.system(size: 8))
                    Text(entry.location)
                        .font(.system(size: 9))
                        .lineLimit(1)
                }
                .foregroundColor(entry.color.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(width: width, height: blockHeight, alignment: .topLeading)
        .background(entry.color.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(entry.color)
                .frame(width: 3),
            alignment: .leading
        )
        .cornerRadius(4)
    }
}

#Preview {
    TimetableView()
}
