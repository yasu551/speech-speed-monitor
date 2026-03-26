import SwiftUI

@main
struct SpeechSpeedMonitorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Speech Speed", systemImage: appState.isMonitoring ? "waveform.circle.fill" : "waveform.circle") {
            ContentView()
                .environmentObject(appState)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)
    }
}
