// EventListView.swift
import SwiftUI

struct EventListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var selectedEvent: Event? = nil
    @State private var showDetail = false
    
    var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: viewModel.selectedDate)
    }
    
    var todayEvents: [Event] {
        viewModel.events(for: viewModel.selectedDate)
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dateTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(todayEvents.count)개의 일정")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            if todayEvents.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("일정이 없어요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(todayEvents) { event in
                        EventRow(event: event)
                            .onTapGesture {
                                selectedEvent = event
                                showDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // 삭제 버튼 (빨간색, 완전 스와이프로 즉시 삭제)
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteEvent(event)
                                    }
                                } label: {
                                    Label("삭제", systemImage: "trash.fill")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                // 편집 버튼 (파란색)
                                Button {
                                    selectedEvent = event
                                    showDetail = true
                                } label: {
                                    Label("편집", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(viewModel: viewModel, event: event)
        }
    }
}

#Preview("일정 있음") {
    let vm = CalendarViewModel()
    vm.addEvent(Event(title: "팀 미팅", date: Date(), memo: "주간 업무 공유", icon: "person.fill", colorName: "blue", notificationEnabled: true))
    vm.addEvent(Event(title: "점심 약속", date: Date(), icon: "fork.knife", colorName: "orange"))
    return EventListView(viewModel: vm)
}

#Preview("일정 없음") {
    EventListView(viewModel: CalendarViewModel())
}

struct EventRow: View {
    let event: Event
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(event.color)
                .frame(width: 4)
                .frame(height: 44)
            
            Image(systemName: event.icon)
                .foregroundColor(event.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !event.memo.isEmpty {
                    Text(event.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if event.notificationEnabled {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
