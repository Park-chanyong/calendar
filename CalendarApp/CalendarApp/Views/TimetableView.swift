// TimetableView.swift
import SwiftUI
import UIKit
import WidgetKit

// MARK: - ViewModel

class TimetableViewModel: ObservableObject {
    @Published var entries: [TimetableEntry] = []

    private let saveKey    = "TimetableEntries"
    private let appGroupID = "group.com.example3.CalendarApp"
    private var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    init() { load() }

    func add(_ entry: TimetableEntry) { entries.append(entry); save() }

    func update(_ entry: TimetableEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(id: UUID) { entries.removeAll { $0.id == id }; save() }

    func entries(for weekday: Int) -> [TimetableEntry] {
        entries.filter { $0.weekday == weekday }.sorted { $0.startTotalMinutes < $1.startTotalMinutes }
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

// MARK: - Form Draft

struct TimetableFormDraft {
    var title = ""; var weekday = 1; var selectedWeekdays: Set<Int> = []
    var startTime: Date; var endTime: Date
    var selectedColor = "blue"; var selectedIcon = ""
    var location = ""; var memo = ""; var isImportant = false

    init() {
        let cal = Calendar.current
        startTime = cal.date(bySettingHour: 9,  minute: 0, second: 0, of: Date()) ?? Date()
        endTime   = cal.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    }

    init(from entry: TimetableEntry) {
        let cal = Calendar.current
        title = entry.title; weekday = max(1, min(5, entry.weekday))
        selectedWeekdays = [max(1, min(5, entry.weekday))]
        selectedColor = entry.colorName; selectedIcon = entry.iconName
        location = entry.location; memo = entry.memo; isImportant = entry.isImportant
        startTime = cal.date(bySettingHour: entry.startHour, minute: entry.startMinute, second: 0, of: Date()) ?? Date()
        endTime   = cal.date(bySettingHour: entry.endHour,   minute: entry.endMinute,   second: 0, of: Date()) ?? Date()
    }

    var hasContent: Bool { !title.isEmpty || !location.isEmpty || !memo.isEmpty || !selectedWeekdays.isEmpty }
    mutating func reset() { self = TimetableFormDraft() }
}

// MARK: - UIKit 제스처 레이어
// SwiftUI의 LongPressGesture+DragGesture.sequenced는 ScrollView 내부에서 신뢰성이 낮아
// UILongPressGestureRecognizer를 사용합니다 (길게 누른 후 드래그가 자연스럽게 이어짐).

final class GestureHostUIView: UIView {
    // 이 뷰가 항상 터치를 수신해야 제스처 인식기가 작동합니다.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { self }
}

struct TimetableGestureLayer: UIViewRepresentable {
    var onTap:            (CGPoint) -> Void
    var onLongPressStart: (CGPoint) -> Void
    var onLongPressDrag:  (CGPoint) -> Void
    var onLongPressEnd:   (CGPoint) -> Void
    var onCancel:          () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> GestureHostUIView {
        let view = GestureHostUIView()
        view.backgroundColor = .clear

        // 탭
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // 길게 누르기 + 드래그 (UILongPressGestureRecognizer는 began→changed 자연 연결)
        let lp = UILongPressGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handleLongPress(_:)))
        lp.minimumPressDuration  = 0.4
        lp.cancelsTouchesInView  = false   // 스크롤뷰와 공존
        view.addGestureRecognizer(lp)
        context.coordinator.longPressRecognizer = lp

        return view
    }

    func updateUIView(_ uiView: GestureHostUIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject {
        var parent: TimetableGestureLayer
        weak var longPressRecognizer: UILongPressGestureRecognizer?

        init(_ parent: TimetableGestureLayer) { self.parent = parent }

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            parent.onTap(r.location(in: r.view))
        }

        @objc func handleLongPress(_ r: UILongPressGestureRecognizer) {
            let loc = r.location(in: r.view)
            switch r.state {
            case .began:              parent.onLongPressStart(loc)
            case .changed:            parent.onLongPressDrag(loc)
            case .ended:              parent.onLongPressEnd(loc)
            case .cancelled, .failed: parent.onCancel()
            default:                  break
            }
        }
    }
}

// MARK: - TimetableView

struct TimetableView: View {
    @ObservedObject var vm: TimetableViewModel
    @State private var showAddEntry = false
    @State private var editingEntry: TimetableEntry? = nil
    @State private var addDraft  = TimetableFormDraft()
    @State private var editDraft = TimetableFormDraft()

    @State private var draggingEntry: TimetableEntry? = nil
    @State private var dragLocation:  CGPoint = .zero
    @State private var isDragging:    Bool    = false

    let hourHeight:    CGFloat = 60
    let timeAxisWidth: CGFloat = 44
    let startHour = 9
    let endHour   = 19
    let weekdays  = ["월", "화", "수", "목", "금"]

    @State private var viewWidth: CGFloat = 390
    var columnWidth: CGFloat { (viewWidth - timeAxisWidth) / 5 }

    var dragSnapColIdx: Int { max(0, min(4, Int((dragLocation.x - timeAxisWidth) / columnWidth))) }
    var dragSnapY: CGFloat {
        let total   = Int((dragLocation.y / hourHeight) * 60) + startHour * 60
        let snapped = (total / 15) * 15
        return CGFloat(snapped - startHour * 60) / 60.0 * hourHeight
    }

    // MARK: body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                weekdayHeader
                Divider()
                gridScrollView
            }
            .navigationTitle("시간표")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEntry = true } label: { Image(systemName: "plus") }
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
                DraftResumeBanner(title: addDraft.title, placeholder: "작성 중인 시간표") {
                    showAddEntry = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: addDraft.hasContent)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { viewWidth = geo.size.width }
                .onChange(of: geo.size.width) { viewWidth = $0 }
        })
    }

    // MARK: - 요일 헤더

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: timeAxisWidth)
            ForEach(0..<5, id: \.self) { i in
                let isToday = Calendar.current.component(.weekday, from: Date()) - 2 == i
                Text(weekdays[i])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isToday ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - 그리드 스크롤뷰

    private var gridScrollView: some View {
        let rows = endHour - startHour + 1
        return ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // 배경: 시간 레이블 + 구분선
                gridBackground(rows: rows)

                // 드래그 중 열 하이라이트
                if isDragging {
                    Rectangle()
                        .fill(Color.blue.opacity(0.07))
                        .frame(width: columnWidth, height: hourHeight * CGFloat(rows))
                        .offset(x: timeAxisWidth + CGFloat(dragSnapColIdx) * columnWidth)
                        .animation(.interactiveSpring(response: 0.15), value: dragSnapColIdx)
                }

                // 시간표 블록 (순수 시각 요소, 제스처 없음)
                ForEach(0..<5, id: \.self) { col in
                    ForEach(vm.entries(for: col + 1)) { entry in
                        TimetableBlock(entry: entry, width: columnWidth - 2, hourHeight: hourHeight)
                            .opacity(draggingEntry?.id == entry.id ? 0.3 : 1.0)
                            .offset(
                                x: timeAxisWidth + CGFloat(col) * columnWidth + 1,
                                y: entryY(entry)
                            )
                    }
                }

                // 드래그 고스트
                if isDragging, let e = draggingEntry {
                    TimetableBlock(entry: e, width: columnWidth - 2, hourHeight: hourHeight)
                        .opacity(0.9)
                        .scaleEffect(1.04)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .offset(
                            x: timeAxisWidth + CGFloat(dragSnapColIdx) * columnWidth + 1,
                            y: dragSnapY
                        )
                        .animation(.interactiveSpring(response: 0.15), value: dragSnapColIdx)
                        .animation(.interactiveSpring(response: 0.15), value: dragSnapY)
                }

                // UIKit 제스처 레이어 (최상단 — 모든 터치 수신)
                TimetableGestureLayer(
                    onTap: { loc in
                        guard !isDragging, let e = entryAt(loc) else { return }
                        editingEntry = e
                    },
                    onLongPressStart: { loc in
                        guard let e = entryAt(loc) else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isDragging    = true
                        draggingEntry = e
                        dragLocation  = loc
                    },
                    onLongPressDrag: { loc in
                        guard isDragging else { return }
                        dragLocation = loc
                    },
                    onLongPressEnd: { loc in
                        guard isDragging, let e = draggingEntry else {
                            isDragging = false; draggingEntry = nil; return
                        }
                        applyDrop(at: loc, for: e)
                    },
                    onCancel: {
                        isDragging = false; draggingEntry = nil
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: hourHeight * CGFloat(rows))
        }
        .scrollDisabled(isDragging)
    }

    // MARK: - 배경 그리드 (시간 레이블 + 구분선)

    private func gridBackground(rows: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // 가로 구분선 + 시간 레이블
            VStack(spacing: 0) {
                ForEach(startHour...endHour, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Text(String(format: "%02d:00", hour))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: timeAxisWidth - 4, alignment: .trailing)
                        VStack(spacing: 0) { Divider(); Spacer() }
                    }
                    .frame(height: hourHeight)
                }
            }
            // 세로 구분선
            HStack(spacing: 0) {
                Spacer().frame(width: timeAxisWidth)
                ForEach(0..<5, id: \.self) { i in
                    Spacer().frame(maxWidth: .infinity)
                    if i < 4 { Divider() }
                }
            }
            .frame(height: hourHeight * CGFloat(rows))
        }
    }

    // MARK: - 헬퍼

    private func entryY(_ entry: TimetableEntry) -> CGFloat {
        CGFloat(entry.startHour - startHour) * hourHeight
            + CGFloat(entry.startMinute) * hourHeight / 60
    }

    /// 그리드 좌표에서 해당 위치의 시간표 항목 반환
    private func entryAt(_ location: CGPoint) -> TimetableEntry? {
        let col = Int((location.x - timeAxisWidth) / columnWidth)
        guard col >= 0, col < 5 else { return nil }
        for entry in vm.entries(for: col + 1) {
            let top    = entryY(entry)
            let height = max(30, CGFloat(entry.durationMinutes) * hourHeight / 60)
            if location.y >= top && location.y < top + height { return entry }
        }
        return nil
    }

    // MARK: - 드롭 적용

    private func applyDrop(at location: CGPoint, for entry: TimetableEntry) {
        let col       = max(0, min(4, Int((location.x - timeAxisWidth) / columnWidth)))
        let totalMin  = Int((location.y / hourHeight) * 60) + startHour * 60
        let snapped   = (totalMin / 15) * 15
        let newStartH = max(startHour, min(endHour - 1, snapped / 60))
        let newStartM = snapped % 60
        let endTotal  = newStartH * 60 + newStartM + entry.durationMinutes

        var updated = entry
        updated.weekday     = col + 1
        updated.startHour   = newStartH
        updated.startMinute = newStartM
        updated.endHour     = min(23, endTotal / 60)
        updated.endMinute   = endTotal % 60

        // 상태 먼저 리셋 → vm.update는 다음 런루프에 실행
        isDragging    = false
        draggingEntry = nil

        Task { @MainActor in
            vm.update(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - 시간표 블록 (순수 표시용)

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
                    Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
                }
                if !entry.iconName.isEmpty {
                    Image(systemName: entry.iconName).font(.system(size: 9)).foregroundColor(entry.color)
                }
                Text(entry.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(entry.color)
                    .lineLimit(2)
            }
            if entry.durationMinutes >= 45 {
                Text(String(format: "%02d:%02d–%02d:%02d",
                            entry.startHour, entry.startMinute, entry.endHour, entry.endMinute))
                    .font(.system(size: 9))
                    .foregroundColor(entry.color.opacity(0.8))
                    .lineLimit(1)
            }
            if !entry.location.isEmpty && entry.durationMinutes >= 60 {
                HStack(spacing: 2) {
                    Image(systemName: "mappin").font(.system(size: 8))
                    Text(entry.location).font(.system(size: 9)).lineLimit(1)
                }
                .foregroundColor(entry.color.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(width: width, height: blockHeight, alignment: .topLeading)
        .background(entry.color.opacity(0.15))
        .overlay(Rectangle().fill(entry.color).frame(width: 3), alignment: .leading)
        .cornerRadius(4)
    }
}

#Preview {
    TimetableView(vm: TimetableViewModel())
}
