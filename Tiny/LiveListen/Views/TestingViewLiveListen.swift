//
// TestingViewLiveListen.swift
// Tiny
//
// Created by Benedictus Yogatama Favian Satyajati on 30/10/25.
//

import SwiftUI

struct TestingLiveListenView: View {
  @StateObject private var manager = HeartbeatSoundManager()
  @State private var showShareSheet = false

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        HStack {
          Circle().fill(manager.isRunning ? Color.green : Color.red).frame(width: 20, height: 20)
          Text(manager.isRunning ? "Listening" : "Stopped").font(.headline)
        }

        // Amplitude display
        VStack(spacing: 10) {
          Text("Signal Strength")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(String(format: "%.3f", manager.amplitudeVal))
            .font(.system(size: 30, weight: .semibold, design: .monospaced))
            .onChange(of: manager.amplitudeVal) { _, newValue in
              print("UI received amplitude update: \(newValue)")
            }

          // Visual amplitude bar
          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              Rectangle()
                .fill(Color.gray.opacity(0.2))
              Rectangle()
                .fill(Color.blue)
                .frame(width: geometry.size.width * CGFloat(min(manager.amplitudeVal * 10, 1.0)))
            }
          }
          .frame(height: 20)
          .cornerRadius(10)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)

        // Gain control (only show when not playing)
        if !manager.isPlaying {
          VStack(spacing: 10) {
            Text("Amplification: \(String(format: "%.1f", manager.gainVal))x")
              .font(.headline)

            Slider(value: Binding(
              get: { manager.gainVal },
              set: { manager.updateGain($0) }
            ), in: 1...50, step: 1.0) // Changed from 1...20 to 1...50
            .accentColor(.blue)

            HStack {
              Text("1x")
                .font(.caption)
              Spacer()
              Text("50x") // Update to match new range
                .font(.caption)
            }
            .foregroundColor(.secondary)
          }
          .padding()
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(15)
        }

        // Last recording playback
        if let recording = manager.lastRecording {
          VStack(spacing: 10) {
            Text("Last Recording")
              .font(.headline)
            Text(recording.fileURL.lastPathComponent)
              .font(.caption)
              .lineLimit(1)

            Button(action: {
              manager.togglePlayback(recording: recording)
            }, label: {
              Label(
                manager.isPlayingPlayback ? "Stop Playback" : "Play Recording",
                systemImage: manager.isPlayingPlayback ? "stop.fill" : "play.fill"
              )
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(15)
            })

            Button(action: {
              self.showShareSheet = true
            }, label: {
              Label("Share Recording", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(15)
            })
            .sheet(isPresented: $showShareSheet) {
              ShareSheet(activityItems: [recording.fileURL])
            }
          }
          .padding()
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(15)
        }

        Spacer()

        VStack(spacing: 15) {
          // Recording control button
          Button(action: {
            if manager.isRecording {
              manager.stopRecording()
            } else {
              manager.startRecording()
            }
          }, label: {
            Label(manager.isRecording ? "Stop Recording" : "Start Recording", systemImage: "mic.circle.fill")
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(manager.isRecording ? Color.yellow.opacity(0.8) : Color.blue)
              .cornerRadius(15)
          })
          .disabled(!manager.isRunning)

          // Main control buttons
          HStack(spacing: 20) {
            Button(action: {
              manager.start()
            }, label: {
              Label("Start", systemImage: "play.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(15)
            })
            .disabled(manager.isRunning)

            Button(action: {
              manager.stop()
            }, label: {
              Label("Stop", systemImage: "stop.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(15)
            })
            .disabled(!manager.isRunning)
          }
        }
      }
      .padding()
      .navigationBarHidden(true)
    }
  }
}

// #Preview {
//  TestingViewLiveListen()
// }
