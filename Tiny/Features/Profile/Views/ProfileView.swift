//
//  ProfileView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 26/11/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSignOutConfirmation = false

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var syncManager: HeartbeatSyncManager
    @StateObject private var heartbeatMainViewModel = HeartbeatMainViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showRoomCode = false
    @State private var isInitialized = false

    // Check if user is a mother
    private var isMother: Bool {
        authService.currentUser?.role == .mother
    }

    var body: some View {
        ZStack {
            Image(themeManager.selectedBackground.imageName)    
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // HEADER
                profileHeader
                    .padding(.bottom, 30)

                // FEATURE CARDS
                featureCards
                    .padding(.horizontal, 16)
                    .frame(height: 160)

                // SETTINGS LIST
                settingsList
            }
        }
        .onAppear {
            // Initialize only once
            if !isInitialized {
                initializeManager()
            }
        }
        .onChange(of: authService.currentUser?.roomCode) { oldValue, newValue in
            // Re-initialize when room code changes
            if newValue != nil && newValue != oldValue {
                print("🔄 Room code updated: \(newValue ?? "nil")")
                initializeManager()
            }
        }
        .sheet(isPresented: $showRoomCode) {
            RoomCodeDisplayView()
                .environmentObject(authService)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - View Components

    private var profileHeader: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let size = geo.size.width * 0.28

                VStack(spacing: 16) {
                    Spacer()

                    NavigationLink {
                        ProfilePhotoDetailView(viewModel: viewModel)
                            .environmentObject(authService)
                    } label: {
                        profileImageView(size: size)
                    }
                    .buttonStyle(.plain)

                    Text(authService.currentUser?.name ?? "Guest")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(width: geo.size.width)
            }
            .frame(height: 260)
        }
        .listRowBackground(Color.clear)
    }

    private func profileImageView(size: CGFloat) -> some View {
        Group {
            if let img = viewModel.profileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var featureCards: some View {
        HStack(spacing: 12) {
            let padding: CGFloat = 5
            let spacing: CGFloat = 12
            let cardWidth = (UIScreen.main.bounds.width - (padding * 5 + spacing)) / 2

            featureCardLeft(width: cardWidth)
            featureCardRight(width: cardWidth)
        }
    }

    private var settingsList: some View {
        List {
            settingsSection
            accountSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var settingsSection: some View {
        Section {
            NavigationLink(destination: ThemeCustomizationView()) {
                Label("Theme", systemImage: "paintpalette.fill")
                    .foregroundStyle(.white)
            }
            NavigationLink(destination: TutorialView()) {
                Label("Tutorial", systemImage: "book.fill")
                    .foregroundStyle(.white)
            }
            Link(destination: URL(string: "https://example.com/privacy")!) {
                Label("Privacy Policy", systemImage: "shield.righthalf.filled")
                    .foregroundStyle(.white)
            }
            Link(destination: URL(string: "https://example.com/terms")!) {
                Label("Terms and Conditions", systemImage: "doc.text")
                    .foregroundStyle(.white)
            }
        }
        .listRowBackground(Color("rowProfileGrey"))
    }

    private var accountSection: some View {
        Section {
            if viewModel.isSignedIn {
                signedInView
            } else {
                signInView
            }
        }
        .listRowBackground(Color("rowProfileGrey"))
    }

    private var signedInView: some View {
        Group {
            Button(role: .destructive) {
                showingSignOutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to sync your data and access personalized features.")
            }
        }
    }

    private var signInView: some View {
        VStack(spacing: 12) {
            // Dummy Sign In Button styled like Apple's
            Button {
                viewModel.signIn()
            } label: {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20, weight: .medium))
                    Text("Sign in with Apple")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(.black)
                .background(Color.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Feature Cards

    private func featureCardLeft(width: CGFloat) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("Connected Journey")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                showRoomCode.toggle()
            }, label: {
                Text("Connect with Your Partner")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            })

            Spacer()
        }
        .frame(width: width, height: width * 0.63, alignment: .topLeading)
        .padding()
        .background(Color("rowProfileGrey"))
        .cornerRadius(14)
    }

    private func featureCardRight(width: CGFloat) -> some View {
        // Calculate current pregnancy week dynamically
        let currentWeek: Int = {
            guard let pregnancyStartDate = UserDefaults.standard.object(forKey: "pregnancyStartDate") as? Date else {
                // Fallback to user's stored pregnancy week if start date not available
                return authService.currentUser?.pregnancyWeeks ?? 0
            }
            
            let calendar = Calendar.current
            let now = Date()
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: pregnancyStartDate, to: now).weekOfYear ?? 0
            return weeksSinceStart
        }()
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("Pregnancy Age")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .center, spacing: 4) {
                Text("\(currentWeek)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("mainViolet"))
                Text("Weeks")
                    .font(.subheadline)
                    .foregroundColor(Color("mainViolet"))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .frame(width: width * 0.65, height: width * 0.63)
        .padding()
        .background(Color("rowProfileGrey"))
        .cornerRadius(14)
    }

    private func initializeManager() {
        Task {
            // Auto-create room for mothers if they don't have one
            if isMother && authService.currentUser?.roomCode == nil {
                do {
                    let roomCode = try await authService.createRoom()
                    print("✅ Room created: \(roomCode)")
                } catch {
                    print("❌ Error creating room: \(error)")
                }
            }

            // Wait a bit for room code to be set
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Now setup the manager with current user data
            let userId = authService.currentUser?.id
            let roomCode = authService.currentUser?.roomCode

            print("🔍 Initializing manager with:")
            print("   User ID: \(userId ?? "nil")")
            print("   Room Code: \(roomCode ?? "nil")")

            await MainActor.run {
                heartbeatMainViewModel.setupManager(
                    modelContext: modelContext,
                    syncManager: syncManager,
                    userId: userId,
                    roomCode: roomCode,
                    userRole: authService.currentUser?.role
                )
                isInitialized = true
            }
        }
    }

}

struct ProfilePhotoDetailView: View {
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var tempUserName: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Image("backgroundPurple")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 30) {
                profilePhotoButton
                    .padding(.top, 80)

                nameEditSection
                    .padding(.horizontal, 30)

                Spacer()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        try? await authService.updateUserName(name: tempUserName)
                        dismiss()
                    }
                }
                .disabled(tempUserName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            tempUserName = authService.currentUser?.name ?? ""
        }
        .sheet(isPresented: $showingPhotoOptions) {
            BottomPhotoPickerSheet(
                showingCamera: $showingCamera,
                showingImagePicker: $showingImagePicker
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: Binding(
                get: { viewModel.profileImage },
                set: { viewModel.profileImage = $0 }
            ), sourceType: .photoLibrary)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePicker(image: Binding(
                get: { viewModel.profileImage },
                set: { viewModel.profileImage = $0 }
            ), sourceType: .camera)
        }
    }

    private var profilePhotoButton: some View {
        Button {
            showingPhotoOptions = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )

                // Camera badge
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white, Color("rowProfileGrey"))
                    .offset(x: -10, y: -10)
            }
        }
        .buttonStyle(.plain)
    }

    private var nameEditSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Name")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
            }

            TextField("Enter your name", text: $tempUserName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
        }
    }
}

struct BottomPhotoPickerSheet: View {
    @Binding var showingCamera: Bool
    @Binding var showingImagePicker: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Change Profile Photo")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 8)

            PhotoPickerButton(
                title: "Take Photo",
                icon: "camera",
                action: {
                    dismiss()
                    showingCamera = true
                }
            )

            PhotoPickerButton(
                title: "Choose From Library",
                icon: "photo.on.rectangle",
                action: {
                    dismiss()
                    showingImagePicker = true
                }
            )
        }
        .padding()
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }
}

private struct PhotoPickerButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("rowProfileGrey"))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct ThemeDummy: View {
    var body: some View {
        Text("Dummy Theme View")
            .navigationTitle("Theme")
    }
}

struct TutorialDummy: View {
    var body: some View {
        Text("Dummy Tutorial View")
            .navigationTitle("Tutorial")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationService())   // <-- mock
        .environmentObject(HeartbeatSyncManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}
