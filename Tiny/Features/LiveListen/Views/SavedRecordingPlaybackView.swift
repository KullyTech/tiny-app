//
//  SavedRecordingPlaybackView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 30/11/25.
//

import SwiftUI
import SwiftData

struct SavedRecordingPlaybackView: View {
    let recording: Recording
    @ObservedObject var heartbeatSoundManager: HeartbeatSoundManager
    @Binding var showTimeline: Bool
    
    @StateObject private var viewModel = SavedRecordingPlaybackViewModel()
    @StateObject var themeManager = ThemeManager()
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                
                topControlsView(geometry: geometry)
                
                orbView(geometry: geometry)
                
                nameAndDateView
                    .zIndex(10)
                
                statusTextView
                
                deleteButton(geometry: geometry)
                
                if viewModel.showSuccessAlert {
                    successAlertView
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .ignoresSafeArea()

        }
        .onAppear {
            viewModel.setupPlayback(
                for: recording,
                manager: heartbeatSoundManager,
                modelContext: modelContext,
                onRecordingUpdated: {
                    heartbeatSoundManager.loadFromSwiftData()
                }
            )
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            Image(themeManager.selectedBackground.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            if viewModel.isPlaying {
                BokehEffectView(amplitude: .constant(0.8))
                    .opacity(0.5)
            }
        }
    }
    
    private func topControlsView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showTimeline = true
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                }
                .glassEffect(.clear)
                
                Spacer()
                
                if viewModel.isEditingName {
                    Button {
                        viewModel.saveName()
                        isNameFieldFocused = false
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "6B5B95"))
                            )
                    }
                    .transition(.opacity.animation(.easeInOut))
                } else {
                    // Normal buttons
                    HStack {
                        Button {
                        } label: {
                            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                        }
                        .glassEffect(.clear)

                        Button {
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                        }
                        .glassEffect(.clear)
                    }
                    .transition(.opacity.animation(.easeInOut))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, geometry.safeAreaInsets.top + 20)
            
            Spacer()
        }
    }
    
    private func orbView(geometry: GeometryProxy) -> some View {
        ZStack {
            AnimatedOrbView()
            
            if viewModel.isPlaying {
                BokehEffectView(amplitude: .constant(0.8))
                    .frame(width: 18, height: 18)
            }
        }
        .frame(width: 200, height: 200)
        .scaleEffect(viewModel.isPlaying ? 1.3 : 0.8)
        .opacity(viewModel.isPlaying ? 1.0 : 0.4)
        .animation(.easeInOut(duration: 0.5), value: viewModel.isPlaying)
        .scaleEffect(viewModel.orbDragScale)
        .offset(y: viewModel.dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.handleDragChange(value: value, geometry: geometry)
                }
                .onEnded { value in
                    viewModel.handleDragEnd(value: value, geometry: geometry) {
                        
                        heartbeatSoundManager.deleteRecording(recording)
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showTimeline = true
                        }
                    }
                }
        )
        .onTapGesture {
            viewModel.togglePlayback(manager: heartbeatSoundManager, recording: recording)
        }
    }
    
    private var statusTextView: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text(viewModel.isPlaying ? "Playing" : "Tap to play")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                if !viewModel.isDraggingToDelete {
                    Text("Drag up to delete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.bottom, 60)
        }
        .opacity(viewModel.isDraggingToDelete ? 0.0 : 1.0)
        .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
    }
    
    private func deleteButton(geometry: GeometryProxy) -> some View {
        Image(systemName: "trash.fill")
            .font(.system(size: 28))
            .foregroundColor(.red)
            .frame(width: 77, height: 77)
            .clipShape(Circle())
            .glassEffect(.clear)
            .scaleEffect(viewModel.deleteButtonScale)
            .position(x: geometry.size.width / 2, y: 100)
            .opacity(viewModel.isDraggingToDelete ? min(abs(viewModel.dragOffset) / 150.0, 1.0) : 0.0)
            .animation(.easeOut(duration: 0.2), value: viewModel.isDraggingToDelete)
            .animation(.easeOut(duration: 0.2), value: viewModel.dragOffset)
    }
    
    private var nameAndDateView: some View {
        VStack {
            Spacer()
                .frame(height: 150)
            
            VStack(spacing: 8) {
                // Editable name
                TextField("Recording Name", text: $viewModel.editedName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .background(
                        viewModel.isEditingName ?
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        : nil
                    )
                    .onChange(of: isNameFieldFocused) { _, isFocused in
                        if isFocused {
                            viewModel.startEditing()
                        } else {
                            if viewModel.isEditingName {
                            }
                        }
                    }
                    .onSubmit {
                        viewModel.saveName()
                        isNameFieldFocused = false
                    }
                
                Text(viewModel.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    private var successAlertView: some View {
        VStack {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Changes saved!")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Your changes is saved.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(20)
            .glassEffect(.clear)
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
        }
    }
}

#Preview {
    let manager = HeartbeatSoundManager()
    let mockRecording = Recording(
        fileURL: URL(fileURLWithPath: "/tmp/test.caf"),
        createdAt: Date()
    )
    
    return SavedRecordingPlaybackView(
        recording: mockRecording,
        heartbeatSoundManager: manager,
        showTimeline: .constant(false)
    )
    .environmentObject(ThemeManager())
}
