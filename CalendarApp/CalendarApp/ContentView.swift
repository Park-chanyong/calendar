import SwiftUI

struct ContentView: View {
    @StateObject private var store = EventStore()
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    @State private var showAddSheet = false

    // Brand colors
    let accent   = Color(hex: "#7c6af7")!
    let accent2  = Color(hex: "#f76a8c")!
    let bgColor  = Color(hex: "#f4f0ff")!
    let surface  = Color.white
    let surface2 = Color(hex: "#ede8ff")!
    let textMain = Color(hex: "#2a2250")!
    let textSub  = Color(hex: "#9990bb")!

    var body: some View {
        ZStack(alignment: .bottom) {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Calendar grid
                CalendarGridView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    store: store,
                    accent: accent,
                    accent2: accent2,
                    surface2: surface2,
                    textMain: textMain,
                    textSub: textSub
                )
                .padding(.horizontal, 4)

                Divider().background(accent.opacity(0.12))

                // Events list
                eventsListView
                    .padding(.bottom, 80)
            }

            // Bottom nav
            bottomNav
        }
        .sheet(isPresented: $showAddSheet) {
            AddEventSheet(
                store: store,
                selectedDate: selectedDate,
                accent: accent,
                accent2: accent2,
                surface: surface,
                surface2: surface2,
                textMain: textMain,
                textSub: textSub
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header
    var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 34, height: 34)
                        .background(surface2)
                        .clipShape(Circle())
                        .foregroundColor(textMain)
                }
                Text(monthTitle)
                    .font(.custom("Helvetica Neue", size: 22).bold())
                    .foregroundStyle(LinearGradient(
                        colors: [accent, accent2],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: 34)
                        .background(surface2)
                        .clipShape(Circle())
                        .foregroundColor(textMain)
                }
            }
            Spacer()
            Button("오늘") { goToday() }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(surface2)
                .clipShape(Capsule())
                .foregroundColor(textSub)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: Events List
    var eventsListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(panelTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textSub)
                Spacer()
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(colors: [accent, accent2],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: accent.opacity(0.4), radius: 6, y: 3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            let dayEvents = store.events(for: selectedDate)
            if dayEvents.isEmpty {
                VStack(spacing: 8) {
                    Text("🌙").font(.system(size: 44))
                    Text("일정이 없어요\n+ 버튼으로 추가해보세요")
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundColor(textSub)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(dayEvents) { ev in
                            EventCardView(
                                event: ev,
                                store: store,
                                textMain: textMain,
                                textSub: textSub
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }

    // MARK: Bottom Nav
    var bottomNav: some View {
        HStack {
            NavItem(icon: "calendar", label: "캘린더", active: true, accent: accent, textSub: textSub)
            NavItem(icon: "star", label: "오늘", active: false, accent: accent, textSub: textSub) { goToday() }
            NavItem(icon: "list.bullet", label: "전체", active: false, accent: accent, textSub: textSub)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    // MARK: Helpers
    var monthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy년 M월"
        fmt.locale = Locale(identifier: "ko_KR")
        return fmt.string(from: currentMonth)
    }

    var panelTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M월 d일 (E)"
        fmt.locale = Locale(identifier: "ko_KR")
        return fmt.string(from: selectedDate)
    }

    func changeMonth(_ dir: Int) {
        var comps = DateComponents()
        comps.month = dir
        if let d = Calendar.current.date(byAdding: comps, to: currentMonth) {
            currentMonth = d
        }
    }

    func goToday() {
        currentMonth = Date()
        selectedDate = Date()
    }
}
