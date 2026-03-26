import AVFoundation
import Foundation

final class SpeechRateMonitor {
    var onRateUpdate: ((Double) -> Void)?
    var onAlert: (() -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private let sessionQueue = DispatchQueue(label: "speech-speed-monitor.audio")
    private let beepPlayer = BeepPlayer()

    private var thresholdSyllablesPerSecond: Double = 5.2
    private var cooldownSeconds: Double = 4.0
    private var isRunning = false
    private var recentFrames: [FrameAnalysis] = []
    private var lastAlertDate = Date.distantPast
    private let analysisWindow: TimeInterval = 3.0
    private let minVoiceDuration: TimeInterval = 0.09
    private let energyGate: Float = 0.015
    private let peakGate: Float = 0.045

    func start(thresholdSyllablesPerSecond: Double, cooldownSeconds: Double) throws {
        guard !isRunning else { return }

        self.thresholdSyllablesPerSecond = thresholdSyllablesPerSecond
        self.cooldownSeconds = cooldownSeconds

        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2_048, format: format) { [weak self] buffer, _ in
            self?.sessionQueue.async {
                self?.analyze(buffer: buffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
        onStatusChange?("監視中")
    }

    func stop() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        recentFrames.removeAll(keepingCapacity: false)
        onRateUpdate?(0)
        onStatusChange?("停止中")
    }

    func updateConfiguration(thresholdSyllablesPerSecond: Double, cooldownSeconds: Double) {
        self.thresholdSyllablesPerSecond = thresholdSyllablesPerSecond
        self.cooldownSeconds = cooldownSeconds
    }

    private func analyze(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var squaredSum: Float = 0
        var peak: Float = 0
        var zeroCrossings = 0
        var previous = channelData[0]

        for index in 0..<frameLength {
            let sample = channelData[index]
            squaredSum += sample * sample
            peak = max(peak, abs(sample))
            if (sample >= 0 && previous < 0) || (sample < 0 && previous >= 0) {
                zeroCrossings += 1
            }
            previous = sample
        }

        let rms = sqrt(squaredSum / Float(frameLength))
        let sampleRate = buffer.format.sampleRate
        let duration = Double(frameLength) / sampleRate
        let timestamp = Date()
        let zcr = Double(zeroCrossings) / duration

        let voiced = rms > energyGate && peak > peakGate && zcr > 900 && zcr < 7_000
        recentFrames.append(.init(timestamp: timestamp, duration: duration, voiced: voiced, peak: peak))
        trimFrames(currentTime: timestamp)

        let voicedSegments = countVoicedSegments()
        let voicedDuration = recentFrames.reduce(0.0) { partial, frame in
            partial + (frame.voiced ? frame.duration : 0)
        }

        let estimatedRate = voicedDuration > 0 ? Double(voicedSegments) / max(voicedDuration, 0.001) : 0
        onRateUpdate?(estimatedRate)

        if estimatedRate >= thresholdSyllablesPerSecond,
           timestamp.timeIntervalSince(lastAlertDate) >= cooldownSeconds {
            lastAlertDate = timestamp
            beepPlayer.playAlert()
            onAlert?()
        }
    }

    private func trimFrames(currentTime: Date) {
        let cutoff = currentTime.addingTimeInterval(-analysisWindow)
        recentFrames.removeAll { $0.timestamp < cutoff }
    }

    private func countVoicedSegments() -> Int {
        var count = 0
        var currentDuration: TimeInterval = 0
        var inVoicedSegment = false

        for frame in recentFrames {
            if frame.voiced {
                currentDuration += frame.duration
                if !inVoicedSegment {
                    inVoicedSegment = true
                }
            } else {
                if inVoicedSegment && currentDuration >= minVoiceDuration {
                    count += 1
                }
                currentDuration = 0
                inVoicedSegment = false
            }
        }

        if inVoicedSegment && currentDuration >= minVoiceDuration {
            count += 1
        }

        return count
    }
}

private struct FrameAnalysis {
    let timestamp: Date
    let duration: TimeInterval
    let voiced: Bool
    let peak: Float
}
