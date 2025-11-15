//
//  VoiceRecorderService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import AVFoundation

class VoiceRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingURL: URL?

    override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Recording

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        guard !isRecording else { return }

        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("voice_\(UUID().uuidString).m4a")

        guard let url = recordingURL else {
            throw VoiceRecorderError.invalidURL
        }

        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        recordingDuration = 0

        // Start timer for duration and audio level
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }

            self.recordingDuration = recorder.currentTime
            recorder.updateMeters()
            self.audioLevel = recorder.averagePower(forChannel: 0)
        }

        AnalyticsService.shared.logEvent(.voiceMessageSent, parameters: [
            "action": "start_recording"
        ])
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        recorder.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil

        AnalyticsService.shared.logEvent(.voiceMessageSent, parameters: [
            "action": "stop_recording",
            "duration": recordingDuration
        ])

        return recordingURL
    }

    func cancelRecording() {
        if isRecording {
            audioRecorder?.stop()
            audioRecorder?.deleteRecording()
            isRecording = false
            timer?.invalidate()
            timer = nil
            recordingDuration = 0
        }

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }

    // MARK: - Playback

    func playAudio(from url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
    }

    func pauseAudio() {
        audioPlayer?.pause()
    }

    func stopAudio() {
        audioPlayer?.stop()
    }

    // MARK: - Utilities

    func getAudioDuration(from url: URL) -> TimeInterval? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            return nil
        }
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            cancelRecording()
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
            PerformanceMonitor.shared.logCrash(error, context: "voice_recording")
        }
        cancelRecording()
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceRecorderService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Reset player
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Playback error: \(error)")
            PerformanceMonitor.shared.logCrash(error, context: "voice_playback")
        }
    }
}

// MARK: - Errors

enum VoiceRecorderError: Error {
    case invalidURL
    case permissionDenied
    case recordingFailed
}
