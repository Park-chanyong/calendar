import SwiftUI

struct EventCardView: View {
    let event: CalendarEvent
    @ObservedObject var store: EventStore
    let textMain: Color
    let textSub: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Text(event.icon)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background((Color(hex: event.color) ?? .purple).opacity(0.13))
                .cornerRadius(12)

            // Body
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textMain)
                    .lineLimit(1)
                Text("⏰ \(event.startTime) ~ \(event.endTime)")
                    .font(.system(size: 11))
                    .foregroundColor(textSub)
                if !event.memo.isEmpty {
                    Text("📝 \(event.memo)")
                        .font(.system(size: 12))
                        .foregroundColor(textSub)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 6) {
                Button {
                    store.delete(id: event.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#f76a8c")!.opacity(0.12))
                        .foregroundColor(Color(hex: "#f76a8c")!)
                        .cornerRadius(8)
                }

                if event.notify {
                    Text("🔔")
                        .font(.system(size: 12))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(hex: "#1dbb8e")!.opacity(0.12))
                        .foregroundColor(Color(hex: "#1dbb8e")!)
                        .cornerRadius(10)
                        .overlay(
                            Capsule().stroke(Color(hex: "#1dbb8e")!.opacity(0.25), lineWidth: 1)
                        )
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "#7c6af7")!.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#7c6af7")!.opacity(0.06), radius: 8, y: 3)
    }
}

struct NavItem: View {
    let icon: String
    let label: String
    let active: Bool
    let accent: Color
    let textSub: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(active ? accent : textSub)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
