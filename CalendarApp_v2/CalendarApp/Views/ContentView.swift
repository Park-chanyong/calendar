// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showAddEvent = false
    
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
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(viewModel: viewModel, selectedDate: viewModel.selectedDate)
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}
