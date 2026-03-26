import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Speech Speed Monitor")
                .font(.title3.weight(.semibold))

            Label(appState.statusText, systemImage: appState.isMonitoring ? "dot.radiowaves.left.and.right" : "pause.circle")
                .foregroundStyle(appState.isMonitoring ? .green : .secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("現在の推定話速")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.currentRate.formatted(.number.precision(.fractionLength(1))) + " syllables/sec")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("警告しきい値")
                    Spacer()
                    Text(appState.thresholdSyllablesPerSecond.formatted(.number.precision(.fractionLength(1))))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $appState.thresholdSyllablesPerSecond, in: 3.0...8.0, step: 0.1) {
                    Text("Threshold")
                } minimumValueLabel: {
                    Text("3.0")
                } maximumValueLabel: {
                    Text("8.0")
                }
                .onChange(of: appState.thresholdSyllablesPerSecond) { _, _ in
                    appState.updateConfiguration()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("警告クールダウン")
                    Spacer()
                    Text(appState.cooldownSeconds.formatted(.number.precision(.fractionLength(0))) + " sec")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $appState.cooldownSeconds, in: 2...10, step: 1) {
                    Text("Cooldown")
                } minimumValueLabel: {
                    Text("2")
                } maximumValueLabel: {
                    Text("10")
                }
                .onChange(of: appState.cooldownSeconds) { _, _ in
                    appState.updateConfiguration()
                }
            }

            if let lastAlertAt = appState.lastAlertAt {
                Text("最終警告: " + lastAlertAt.formatted(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(appState.isMonitoring ? "監視を停止" : "監視を開始") {
                appState.toggleMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
    }
}
