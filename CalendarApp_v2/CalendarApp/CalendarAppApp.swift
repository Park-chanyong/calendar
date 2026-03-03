// CalendarAppApp.swift
import SwiftUI

@main
struct CalendarAppApp: App {
    @AppStorage("appColorScheme") private var colorSchemeRaw: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredColorScheme)
                .onAppear  { applyWindowStyle() }
                .onChange(of: colorSchemeRaw) { _ in applyWindowStyle() }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    // 시트 등 별도 UIViewController에도 색상 모드가 반영되도록 UIWindow에 직접 적용
    private func applyWindowStyle() {
        let style: UIUserInterfaceStyle
        switch colorSchemeRaw {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.windows.forEach { $0.overrideUserInterfaceStyle = style }
    }
}
