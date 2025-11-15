//
//  VoiceRecorderView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct VoiceRecorderView: View {
    @StateObject private var recorder = VoiceRecorderService()
    let onSend: (URL) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Recording Indicator
            ZStack {
                // Pulsing circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                        .animation(
                            Animation
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.5),
                            value: scale
                        )
                }
                .frame(width: 120, height: 120)

                // Microphone icon
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                scale = 2.0
            }

            // Duration
            Text(recorder.formatDuration(recorder.recordingDuration))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.primary)

            // Audio Level Indicator
            HStack(spacing: 4) {
                ForEach(0..<20) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(audioLevelColor(for: index))
                        .frame(width: 4, height: audioBarHeight(for: index))
                }
            }
            .frame(height: 40)

            Spacer()

            // Action Buttons
            HStack(spacing: 40) {
                // Cancel Button
                Button(action: {
                    recorder.cancelRecording()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 64, height: 64)

                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }

                // Send Button
                Button(action: {
                    if let url = recorder.stopRecording() {
                        onSend(url)
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 64, height: 64)

                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            do {
                try recorder.startRecording()
            } catch {
                print("Failed to start recording: \(error)")
                dismiss()
            }
        }
    }

    private func audioLevelColor(for index: Int) -> Color {
        let normalizedLevel = (recorder.audioLevel + 60) / 60 // Convert from dB to 0-1
        let threshold = Float(index) / 20.0

        if normalizedLevel > threshold {
            return Color.blue
        } else {
            return Color(.systemGray5)
        }
    }

    private func audioBarHeight(for index: Int) -> CGFloat {
        let normalizedLevel = CGFloat((recorder.audioLevel + 60) / 60)
        let threshold = CGFloat(index) / 20.0

        if normalizedLevel > threshold {
            return 40
        } else {
            return 8
        }
    }
}

// MARK: - Voice Message Player

struct VoiceMessagePlayer: View {
    let audioURL: URL
    @StateObject private var recorder = VoiceRecorderService()
    @State private var isPlaying = false
    @State private var duration: TimeInterval = 0

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause Button
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
            }

            // Waveform visualization (simplified)
            HStack(spacing: 2) {
                ForEach(0..<30) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: CGFloat.random(in: 8...24))
                }
            }

            // Duration
            Text(recorder.formatDuration(duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            duration = recorder.getAudioDuration(from: audioURL) ?? 0
        }
    }

    private func togglePlayback() {
        if isPlaying {
            recorder.pauseAudio()
        } else {
            do {
                try recorder.playAudio(from: audioURL)
            } catch {
                print("Failed to play audio: \(error)")
            }
        }
        isPlaying.toggle()
    }
}

#Preview {
    VoiceRecorderView { url in
        print("Send voice message: \(url)")
    }
}
