// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showAddEvent = false
    @State private var showWidgetGuide = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 뷰 모드 전환 세그먼트
                Picker("보기 방식", selection: $viewModel.viewMode) {
                    Text("월별").tag(CalendarViewModel.ViewMode.month)
                    Text("주별").tag(CalendarViewModel.ViewMode.week)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // 캘린더 뷰
                if viewModel.viewMode == .month {
                    MonthView(viewModel: viewModel)
                } else {
                    WeekView(viewModel: viewModel)
                }

                // 선택된 날짜의 일정 목록
                EventListView(viewModel: viewModel)
            }
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("오늘") {
                        viewModel.goToToday()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showWidgetGuide = true
                        } label: {
                            Image(systemName: "square.on.square")
                        }
                        Button {
                            showAddEvent = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(viewModel: viewModel, selectedDate: viewModel.selectedDate)
            }
            .sheet(isPresented: $showWidgetGuide) {
                WidgetGuideView()
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
        .onOpenURL { url in
            guard url.scheme == "calendarapp",
                  url.host == "date",
                  let dateStr = url.pathComponents.last else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateStr) {
                viewModel.selectedDate = date
                viewModel.currentMonth = date
            }
        }
    }
}

// MARK: - Widget Guide Sheet

struct WidgetGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(icon: String, color: Color, title: String, description: String)] = [
        ("hand.tap.fill",        .blue,   "홈 화면 편집 모드 진입",  "홈 화면의 빈 곳을 길게 누르거나\n앱 아이콘을 길게 눌러 편집 모드로 들어가세요."),
        ("plus.circle.fill",     .green,  "위젯 추가 버튼 탭",      "화면 왼쪽 상단의 + 버튼을 탭하세요."),
        ("magnifyingglass",      .orange, "캘린더 앱 검색",         "검색창에 '캘린더'를 입력해 이 앱을 찾으세요."),
        ("square.grid.2x2.fill", .purple, "중형 위젯 선택",         "위젯 크기 중 '중형'을 선택한 뒤\n'위젯 추가'를 탭하세요."),
        ("checkmark.circle.fill",.teal,   "완료",                   "홈 화면에서 이번 주 일정을\n바로 확인할 수 있습니다."),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                            .padding(.top, 32)
                        Text("위젯 추가하기")
                            .font(.title2.bold())
                        Text("홈 화면에서 오늘 일정을 바로 확인하세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)

                    // Steps
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(steps.indices, id: \.self) { index in
                            StepRow(
                                number: index + 1,
                                icon: steps[index].icon,
                                color: steps[index].color,
                                title: steps[index].title,
                                description: steps[index].description,
                                isLast: index == steps.count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

private struct StepRow: View {
    let number: Int
    let icon: String
    let color: Color
    let title: String
    let description: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 44)

            // Text column
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(color, in: Circle())
                    Text(title)
                        .font(.subheadline.bold())
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
