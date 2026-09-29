import SwiftUI
import ServiceManagement

/// The drop-down you get from the menu bar icon.
struct MenuView: View {
    @AppStorage("fullScreen") private var fullScreen = true
    @AppStorage("chime") private var chime = false
    @AppStorage("logDay") private var logDay = ""
    @AppStorage("logCount") private var logCount = 0
    @AppStorage("logSeconds") private var logSeconds = 0.0
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Between").font(helvetica(15))
                Spacer()
                Text("Pick a breath").font(helvetica(11)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            ForEach(BreathSequence.all) { seq in
                SequenceRow(seq: seq) { SessionPresenter.shared.start(seq) }
            }

            Divider().padding(.horizontal, 14).padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Go full screen on start", isOn: $fullScreen)
                Toggle("Soft tone on each phase", isOn: $chime)
                Toggle("Open at login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { on in
                        do {
                            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {
                            openAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            .toggleStyle(.checkbox)
            .font(helvetica(12))
            .padding(.horizontal, 14)

            HStack {
                Text(todayText).font(helvetica(11)).foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(helvetica(11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 12)
        }
        .frame(width: 330)
        .tracking(textTracking)
    }

    private var todayText: String {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        guard logDay == today, logCount > 0 else { return "No sessions yet today" }
        let mins = Int((logSeconds / 60).rounded())
        return "Today: \(logCount) session\(logCount == 1 ? "" : "s") · \(mins) min"
    }
}

struct SequenceRow: View {
    let seq: BreathSequence
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(seq.scene.swatch)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(seq.name).font(helvetica(13))
                    Text("\(seq.use) · \(seq.tag)")
                        .font(helvetica(11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(formatTime(seq.total))
                    .font(helvetica(11))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(hovering ? Color.primary.opacity(0.08) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .padding(.horizontal, 4)
    }
}
