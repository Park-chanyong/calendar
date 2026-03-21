// ContentView.swift
import SwiftUI

struct ContentView: View {
    @AppStorage("appColorScheme") private var colorSchemeRaw: String = "system"
    @AppStorage("hasSeenUserGuide") private var hasSeenUserGuide = false
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var timetableViewModel = TimetableViewModel()
    @State private var selectedTab = 0
    @State private var showUserGuide = false

    // TabView 바깥에서 읽으므로 앱 override 이전의 실제 시스템 색상
    @Environment(\.colorScheme) private var systemColorScheme

    private var preferredColorScheme: ColorScheme? {
        colorSchemeRaw == "light" ? .light : colorSchemeRaw == "dark" ? .dark : nil
    }

    init() {
        // 탭바 레이블이 선택 여부와 관계없이 항상 보이도록 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance    = appearance
        UITabBar.appearance().scrollEdgeAppearance  = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimetableView(vm: timetableViewModel)
                .tabItem { Label("시간표", systemImage: "tablecells") }
                .tag(0)

            CalendarView(viewModel: viewModel)
                .tabItem { Label("캘린더", systemImage: "calendar.day.timeline.left") }
                .tag(1)

            AllView(calendarViewModel: viewModel, timetableViewModel: timetableViewModel, systemColorScheme: systemColorScheme)
                .tabItem { Label("전체", systemImage: "list.bullet.rectangle") }
                .tag(2)
        }
        .preferredColorScheme(preferredColorScheme)
        .tint(.blue)
        .onAppear {
            NotificationManager.shared.requestPermission()
            if !hasSeenUserGuide {
                hasSeenUserGuide = true
                showUserGuide = true
            }
        }
        .sheet(isPresented: $showUserGuide) {
            UserGuideView()
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
                selectedTab = 1
            }
        }
    }
}

// MARK: - Calendar Tab

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showAddEvent = false
    @State private var addEventDraft = CalendarEventDraft()  // 추가 폼 임시 저장

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("보기 방식", selection: $viewModel.viewMode) {
                    Text("월별").tag(CalendarViewModel.ViewMode.month)
                    Text("주별").tag(CalendarViewModel.ViewMode.week)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if viewModel.viewMode == .month {
                    MonthView(viewModel: viewModel)
                } else {
                    WeekView(viewModel: viewModel)
                }

                EventListView(viewModel: viewModel)
            }
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("오늘") { viewModel.goToToday() }
                        .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEvent = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(viewModel: viewModel, draft: $addEventDraft)
            }
            .onChange(of: showAddEvent) { isShowing in
                // 폼이 새로 열릴 때(draft가 비어 있는 경우)만 선택한 날짜로 초기화
                if isShowing && addEventDraft.title.isEmpty {
                    addEventDraft.date = viewModel.selectedDate
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if addEventDraft.hasContent && !showAddEvent {
                DraftResumeBanner(
                    title: addEventDraft.title,
                    placeholder: "작성 중인 일정"
                ) {
                    showAddEvent = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: addEventDraft.hasContent)
    }
}

// MARK: - Draft Resume Banner

struct DraftResumeBanner: View {
    let title: String
    let placeholder: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text(title.isEmpty ? placeholder : title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Text("이어서 작성")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appearance Settings Sheet

struct AppearanceSettingsView: View {
    let systemColorScheme: ColorScheme          // ContentView에서 전달받은 진짜 시스템 색상
    @AppStorage("appColorScheme") private var colorSchemeRaw: String = "system"
    @Environment(\.dismiss) private var dismiss

    private let options: [(value: String, label: String, icon: String)] = [
        ("system", "시스템 설정",  "iphone"),
        ("light",  "라이트 모드", "sun.max"),
        ("dark",   "다크 모드",  "moon"),
    ]

    // nil 대신 항상 구체 값 반환 → dark→nil 전환 시 SwiftUI 미반영 버그 방지
    private var resolvedScheme: ColorScheme {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return systemColorScheme   // 시스템 설정: 진짜 시스템 값 사용
        }
    }

    var body: some View {
        NavigationView {
            List(options, id: \.value) { option in
                Button {
                    colorSchemeRaw = option.value
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .frame(width: 24)
                            .foregroundStyle(.blue)
                        Text(option.label)
                            .foregroundStyle(.primary)
                        Spacer()
                        if colorSchemeRaw == option.value {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("화면 모드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .preferredColorScheme(resolvedScheme)
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

// MARK: - User Guide

private struct GuidePage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let description: String
    let features: [(icon: String, color: Color, text: String)]
}

private struct GuidePageView: View {
    let page: GuidePage

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(page.color)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                Text(page.title)
                    .font(.title.bold())
                    .padding(.bottom, 4)

                Text(page.subtitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(page.color)
                    .padding(.bottom, 12)

                Text(page.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                if !page.features.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(page.features.indices, id: \.self) { i in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(page.features[i].color.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: page.features[i].icon)
                                        .font(.system(size: 15))
                                        .foregroundStyle(page.features[i].color)
                                }
                                Text(page.features[i].text)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct UserGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showSkipAlert = false

    private let pages: [GuidePage] = [
        GuidePage(
            icon: "hand.wave.fill",
            color: .blue,
            title: "환영합니다!",
            subtitle: "앱 사용 설명서",
            description: "시간표, 일정, 과제·시험을 한 곳에서\n간편하게 관리해 보세요.",
            features: []
        ),
        GuidePage(
            icon: "tablecells",
            color: .indigo,
            title: "시간표",
            subtitle: "나만의 수업 시간표를 만들어요",
            description: "수업을 등록해 두면 오늘 시간표가\n전체 탭에 자동으로 표시돼요.",
            features: [
                ("plus.circle.fill",           .indigo, "+ 버튼으로 수업 추가"),
                ("hand.draw.fill",             .indigo, "길게 눌러 드래그로 시간 조정"),
                ("exclamationmark.circle.fill", .orange, "중요 수업 표시 가능"),
            ]
        ),
        GuidePage(
            icon: "calendar.day.timeline.left",
            color: .green,
            title: "캘린더",
            subtitle: "일정·시험·과제를 등록해요",
            description: "월별·주별로 일정을 확인하고\n카테고리별로 구분해 관리할 수 있어요.",
            features: [
                ("plus.circle.fill",      .green,  "날짜 선택 후 + 버튼으로 일정 추가"),
                ("pencil.and.ruler.fill", .red,    "시험 카테고리로 시험 일정 등록"),
                ("checklist",            .orange, "과제 카테고리로 마감일 관리"),
                ("bell.fill",            .blue,   "알림 설정으로 놓치지 않기"),
            ]
        ),
        GuidePage(
            icon: "list.bullet.rectangle",
            color: .purple,
            title: "전체",
            subtitle: "오늘 하루를 한눈에 파악해요",
            description: "오늘의 시간표와 일정,\n다가오는 시험·과제를 모아서 보여줘요.",
            features: [
                ("sun.max.fill",          .yellow, "오늘 시간표 & 일정 한눈에 보기"),
                ("pencil.and.ruler.fill", .red,    "2주 이내 시험 자동 표시"),
                ("checklist",            .orange, "2주 이내 과제 마감 자동 표시"),
                ("gearshape.fill",       .gray,   "상단 ⚙ 버튼으로 화면 모드 변경"),
            ]
        ),
        GuidePage(
            icon: "square.on.square",
            color: .teal,
            title: "홈 화면 위젯",
            subtitle: "오늘 일정을 홈에서 바로 확인",
            description: "위젯을 추가하면 앱을 열지 않아도\n오늘 일정을 홈 화면에서 바로 볼 수 있어요.",
            features: [
                ("hand.tap.fill",    .teal, "홈 화면 빈 곳을 길게 눌러 편집 모드"),
                ("plus.circle.fill", .teal, "+ 버튼 → '캘린더' 검색 → 중형 선택"),
                ("square.on.square", .teal, "자세한 안내: 전체 탭 상단 □ 버튼"),
            ]
        ),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        GuidePageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 20) {
                    // 페이지 인디케이터
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index
                                      ? pages[currentPage].color
                                      : Color.secondary.opacity(0.3))
                                .frame(width: currentPage == index ? 8 : 6,
                                       height: currentPage == index ? 8 : 6)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }

                    if currentPage < pages.count - 1 {
                        HStack {
                            Button("건너뛰기") { showSkipAlert = true }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                withAnimation { currentPage += 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("다음")
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 13)
                                .background(pages[currentPage].color, in: Capsule())
                            }
                        }
                        .padding(.horizontal, 28)
                    } else {
                        Button { dismiss() } label: {
                            Text("시작하기")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(pages[currentPage].color,
                                            in: RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 28)
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("나중에 다시 볼 수 있어요", isPresented: $showSkipAlert) {
                Button("확인", role: .cancel) { dismiss() }
            } message: {
                Text("전체 탭 오른쪽 상단의 ? 버튼을 누르면\n언제든지 사용 설명서를 다시 볼 수 있어요.")
            }
        }
    }
}

// MARK: - All Tab

struct AllView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var timetableViewModel: TimetableViewModel
    let systemColorScheme: ColorScheme          // 실제 시스템 색상 (ContentView에서 전달)
    @State private var showUserGuide = false
    @State private var showWidgetGuide = false
    @State private var showSettings = false
    @State private var selectedEvent: Event? = nil

    private let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date()) - 1
    }

    private var todayTimetableEntries: [TimetableEntry] {
        timetableViewModel.entries(for: todayWeekday)
    }

    private var todayEvents: [Event] {
        calendarViewModel.events.filter {
            Calendar.current.isDateInToday($0.date)
        }.sorted { $0.date < $1.date }
    }

    private var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        return calendarViewModel.events.filter {
            let d = Calendar.current.startOfDay(for: $0.date)
            return d > today && d <= nextWeek && $0.category == .general
        }.sorted { $0.date < $1.date }
    }

    private var upcomingExams: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: today)!
        return calendarViewModel.events.filter {
            let d = Calendar.current.startOfDay(for: $0.date)
            return $0.category == .exam && d >= today && d <= twoWeeks
        }.sorted { $0.date < $1.date }
    }

    private var upcomingAssignments: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: today)!
        return calendarViewModel.events.filter {
            let d = Calendar.current.startOfDay(for: $0.date)
            return $0.category == .assignment && d >= today && d <= twoWeeks
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationView {
            List {
                // 오늘 날짜 헤더
                Section {
                    HStack(spacing: 12) {
                        VStack(alignment: .center, spacing: 2) {
                            Text(todayMonthDay)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(todayWeekdayLabel)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64)
                        Divider()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("오늘 일정")
                                .font(.subheadline.bold())
                            let totalCount = todayTimetableEntries.count + todayEvents.count
                            Text(totalCount == 0 ? "일정 없음" : "\(totalCount)개")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 오늘 시간표
                if !todayTimetableEntries.isEmpty {
                    Section("시간표") {
                        ForEach(todayTimetableEntries) { entry in
                            AllTimetableRow(entry: entry)
                        }
                    }
                }

                // 오늘 캘린더 일정
                if !todayEvents.isEmpty {
                    Section("캘린더 일정") {
                        ForEach(todayEvents) { event in
                            AllEventRow(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }

                // 오늘 항목이 없는 경우
                if todayTimetableEntries.isEmpty && todayEvents.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text("오늘 일정이 없습니다")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    }
                }

                // 다가오는 시험 (2주 이내)
                if !upcomingExams.isEmpty {
                    Section {
                        ForEach(upcomingExams) { event in
                            AllEventRow(event: event, showDate: true)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                        }
                    } header: {
                        Label("다가오는 시험", systemImage: "pencil.and.ruler.fill")
                            .foregroundStyle(.red)
                    }
                }

                // 마감 임박 과제 (2주 이내)
                if !upcomingAssignments.isEmpty {
                    Section {
                        ForEach(upcomingAssignments) { event in
                            AllEventRow(event: event, showDate: true)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                        }
                    } header: {
                        Label("마감 임박 과제", systemImage: "checklist")
                            .foregroundStyle(.orange)
                    }
                }

                // 이번 주 예정 일정 (일반)
                if !upcomingEvents.isEmpty {
                    Section("이번 주 예정") {
                        ForEach(upcomingEvents) { event in
                            AllEventRow(event: event, showDate: true)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }
            }
            .navigationTitle("전체")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showUserGuide = true } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                        Button { showWidgetGuide = true } label: {
                            Image(systemName: "square.on.square")
                        }
                    }
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(viewModel: calendarViewModel, event: event)
            }
            .sheet(isPresented: $showSettings) {
                AppearanceSettingsView(systemColorScheme: systemColorScheme)
            }
            .sheet(isPresented: $showWidgetGuide) {
                WidgetGuideView()
            }
            .sheet(isPresented: $showUserGuide) {
                UserGuideView()
            }
        }
    }

    private var todayMonthDay: String {
        let cal = Calendar.current
        let m = cal.component(.month, from: Date())
        let d = cal.component(.day, from: Date())
        return "\(m)/\(d)"
    }

    private var todayWeekdayLabel: String {
        weekdayNames[todayWeekday]
    }
}

private struct AllTimetableRow: View {
    let entry: TimetableEntry

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.color)
                .frame(width: 4, height: 40)
            if !entry.iconName.isEmpty {
                Image(systemName: entry.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(entry.color)
                    .frame(width: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(String(format: "%02d:%02d – %02d:%02d",
                            entry.startHour, entry.startMinute,
                            entry.endHour, entry.endMinute))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if entry.isImportant {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct AllEventRow: View {
    let event: Event
    var showDate: Bool = false

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let start = f.string(from: event.date)
        switch event.category {
        case .exam:
            if let end = event.endDate {
                return "\(start) ~ \(f.string(from: end))"
            }
            return start
        case .assignment:
            if showDate { return "마감 \(start)" }
            return "마감 \(start)"
        case .general:
            return start
        }
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f.string(from: event.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(event.category != .general ? event.category.badgeColor : event.color)
                .frame(width: 4, height: 44)
            Image(systemName: event.icon)
                .font(.system(size: 14))
                .foregroundStyle(event.category != .general ? event.category.badgeColor : event.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(event.title)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    if event.category != .general {
                        Text(event.category.label)
                            .font(.caption2.bold())
                            .foregroundStyle(event.category.badgeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(event.category.badgeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 6) {
                    if !event.subjectName.isEmpty && event.category != .general {
                        Text(event.subjectName)
                            .font(.caption)
                            .foregroundStyle(event.category.badgeColor)
                    }
                    if showDate {
                        Text(dateLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text(timeLabel)
                .font(.caption)
                .foregroundStyle(event.category == .exam ? .red
                               : event.category == .assignment ? .orange : .secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ContentView()
}
