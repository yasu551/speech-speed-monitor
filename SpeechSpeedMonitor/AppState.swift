import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var thresholdSyllablesPerSecond: Double = 5.2
    @Published var cooldownSeconds: Double = 4.0
    @Published var isMonitoring = false
    @Published var currentRate: Double = 0
    @Published var lastAlertAt: Date?
    @Published var statusText = "停止中"

    let rateMonitor: SpeechRateMonitor

    init() {
        self.rateMonitor = SpeechRateMonitor()
        wireCallbacks()
    }

    func toggleMonitoring() {
        if isMonitoring {
            rateMonitor.stop()
            isMonitoring = false
            statusText = "停止中"
            return
        }

        do {
            try rateMonitor.start(
                thresholdSyllablesPerSecond: thresholdSyllablesPerSecond,
                cooldownSeconds: cooldownSeconds
            )
            isMonitoring = true
            statusText = "監視中"
        } catch {
            statusText = "開始失敗: \(error.localizedDescription)"
        }
    }

    func updateConfiguration() {
        rateMonitor.updateConfiguration(
            thresholdSyllablesPerSecond: thresholdSyllablesPerSecond,
            cooldownSeconds: cooldownSeconds
        )
    }

    private func wireCallbacks() {
        rateMonitor.onRateUpdate = { [weak self] rate in
            Task { @MainActor in
                self?.currentRate = rate
            }
        }

        rateMonitor.onAlert = { [weak self] in
            Task { @MainActor in
                self?.lastAlertAt = Date()
                self?.statusText = "早口を検知"
            }
        }

        rateMonitor.onStatusChange = { [weak self] status in
            Task { @MainActor in
                self?.statusText = status
            }
        }
    }
}
