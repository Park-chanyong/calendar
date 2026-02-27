import Foundation
import Combine

class EventStore: ObservableObject {
    @Published var events: [CalendarEvent] = []

    private let saveKey = "cal_events"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data)
        else { return }
        events = decoded
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    func add(_ event: CalendarEvent) {
        events.append(event)
        save()
    }

    func delete(id: String) {
        events.removeAll { $0.id == id }
        save()
    }

    func events(for date: Date) -> [CalendarEvent] {
        let key = dateKey(date)
        return events.filter { $0.date == key }
    }

    func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
