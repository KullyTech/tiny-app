//
//  AuthenticationService.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AuthenticationServices
import CryptoKit
internal import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private let database = Firestore.firestore()
    
    private var currentNonce: String?
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let firebaseUser = auth.currentUser {
            fetchUserData(userId: firebaseUser.uid)
        }
    }
    
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Credentials"])
        }
        
        guard let nonce = currentNonce else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token."])
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data."])
        }
        
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
        
        let result = try await auth.signIn(with: credential)
        
        let userDoc = try await database.collection("users").document(result.user.uid).getDocument()
        
        if !userDoc.exists {
            var displayName: String?
            if let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                if displayName?.isEmpty == true {
                    displayName = nil
                }
            }
            
            let newUser = User(
                id: result.user.uid,
                email: result.user.email ?? "",
                name: displayName,
                role: nil,
                pregnancyWeeks: nil,
                roomCode: nil,
                createdAt: Date()
            )
            
            try database.collection("users").document(result.user.uid).setData(from: newUser)
            self.currentUser = newUser
        } else {
            fetchUserData(userId: result.user.uid)
        }
        isAuthenticated = true
    }
    
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    func updateUserRole(role: UserRole, pregnancyWeeks: Int? = nil, roomCode: String? = nil) async throws {
        guard let userId = auth.currentUser?.uid else {
            return
        }
        
        var updateData: [String: Any] = ["role": role.rawValue]
        
        if role == .mother, let weeks = pregnancyWeeks {
            updateData["pregnancyWeeks"] = weeks
        }
        
        if role == .father, let code = roomCode, !code.isEmpty {
            updateData["roomCode"] = code
        }
        
        try await database.collection("users").document(userId).updateData(updateData)
        fetchUserData(userId: userId)
    }
    
    func updateUserName(name: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            return
        }
        
        try await database.collection("users").document(userId).updateData(["name": name])
        fetchUserData(userId: userId)
    }
    
    func createRoom() async throws -> String {
        guard let userId = auth.currentUser?.uid,
              currentUser?.role == .mother else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Only mothers can create rooms!"])
        }
        
        let roomCode = generateRoomCode()
        
        let room = Room(
            code: roomCode,
            motherUserId: userId,
            fatherUserId: nil,
            createdAt: Date()
        )
        
        let docRef = try database.collection("rooms").addDocument(from: room)
        
        try await database.collection("users").document(userId).updateData(["roomCode": roomCode])
        fetchUserData(userId: userId)
        
        return roomCode
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])
        }
        
        let userId = user.uid
        
        do {
            print("🗑️ Starting account deletion for user: \(userId)")
            
            // 1. Delete all heartbeat recordings from Firestore and Storage
            print("🗑️ Deleting heartbeat recordings...")
            
            // Query by motherUserId (the field used in your schema)
            var heartbeatsSnapshot = try await database.collection("heartbeats")
                .whereField("motherUserId", isEqualTo: userId)
                .getDocuments()
            
            print("   Found \(heartbeatsSnapshot.documents.count) heartbeats by motherUserId")
            
            // Also check for any heartbeats with userId field (legacy/fallback)
            let legacyHeartbeats = try await database.collection("heartbeats")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            if !legacyHeartbeats.documents.isEmpty {
                print("   Found \(legacyHeartbeats.documents.count) heartbeats by userId (legacy)")
            }
            
            // Combine both results
            var allHeartbeatDocs = heartbeatsSnapshot.documents
            allHeartbeatDocs.append(contentsOf: legacyHeartbeats.documents)
            
            for document in allHeartbeatDocs {
                let data = document.data()
                
                // Delete from Firebase Storage if audioURL exists
                if let audioURL = data["firebaseStorageURL"] as? String, !audioURL.isEmpty {
                    do {
                        let storageRef = Storage.storage().reference(forURL: audioURL)
                        try await storageRef.delete()
                        print("   ✅ Deleted audio file from Storage: \(document.documentID)")
                    } catch {
                        print("   ⚠️ Failed to delete audio file \(document.documentID): \(error.localizedDescription)")
                    }
                }
                
                // Delete from Firestore
                try await database.collection("heartbeats").document(document.documentID).delete()
                print("   ✅ Deleted heartbeat document: \(document.documentID)")
            }
            
            print("🗑️ Deleted \(allHeartbeatDocs.count) heartbeat recordings")
            
            // 2. Delete all moments from Firestore and Storage
            print("🗑️ Deleting moments...")
            
            // Query by motherUserId (the field used in your schema)
            var momentsSnapshot = try await database.collection("moments")
                .whereField("motherUserId", isEqualTo: userId)
                .getDocuments()
            
            print("   Found \(momentsSnapshot.documents.count) moments by motherUserId")
            
            // Also check for any moments with userId field (legacy/fallback)
            let legacyMoments = try await database.collection("moments")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            if !legacyMoments.documents.isEmpty {
                print("   Found \(legacyMoments.documents.count) moments by userId (legacy)")
            }
            
            // Combine both results
            var allMomentDocs = momentsSnapshot.documents
            allMomentDocs.append(contentsOf: legacyMoments.documents)
            
            for document in allMomentDocs {
                let data = document.data()
                
                // Delete from Firebase Storage if imageURL exists
                if let imageURL = data["firebaseStorageURL"] as? String, !imageURL.isEmpty {
                    do {
                        let storageRef = Storage.storage().reference(forURL: imageURL)
                        try await storageRef.delete()
                        print("   ✅ Deleted moment image from Storage: \(document.documentID)")
                    } catch {
                        print("   ⚠️ Failed to delete moment image \(document.documentID): \(error.localizedDescription)")
                    }
                }
                
                // Delete from Firestore
                try await database.collection("moments").document(document.documentID).delete()
                print("   ✅ Deleted moment document: \(document.documentID)")
            }
            
            print("🗑️ Deleted \(allMomentDocs.count) moments")
            
            // 3. Handle room cleanup
            if let roomCode = currentUser?.roomCode {
                print("🗑️ Cleaning up room: \(roomCode)")
                
                // Find the room
                let snapshot = try await database.collection("rooms")
                    .whereField("code", isEqualTo: roomCode)
                    .limit(to: 1)
                    .getDocuments()
                
                if let roomDoc = snapshot.documents.first {
                    let roomData = roomDoc.data()
                    let motherUserId = roomData["motherUserId"] as? String
                    let fatherUserId = roomData["fatherUserId"] as? String
                    
                    // If user is the mother, delete the entire room
                    if motherUserId == userId {
                        print("🗑️ Deleting room (user is mother)")
                        try await database.collection("rooms").document(roomDoc.documentID).delete()
                    }
                    // If user is the father, just remove their reference
                    else if fatherUserId == userId {
                        print("🗑️ Removing father from room")
                        try await database.collection("rooms").document(roomDoc.documentID).updateData([
                            "fatherUserId": FieldValue.delete()
                        ])
                    }
                }
            }
            
            // 4. Delete user document from Firestore
            print("🗑️ Deleting user document from Firestore")
            try await database.collection("users").document(userId).delete()
            
            // 5. Delete the Firebase Auth account
            print("🗑️ Deleting Firebase Auth account")
            try await user.delete()
            
            // 6. Clear local state
            currentUser = nil
            isAuthenticated = false
            
            print("✅ Account successfully deleted from Firebase")
            
        } catch let error as NSError {
            // Handle re-authentication requirement
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw NSError(
                    domain: "AuthError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "For security reasons, please sign out and sign in again before deleting your account."]
                )
            }
            print("❌ Error during account deletion: \(error)")
            throw error
        }
    }
    
    private func fetchUserData(userId: String) {
        database.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Manually decode the user data
            let user = User(
                id: snapshot.documentID,
                email: data["email"] as? String ?? "",
                name: data["name"] as? String,
                role: (data["role"] as? String).flatMap { UserRole(rawValue: $0) },
                pregnancyWeeks: data["pregnancyWeeks"] as? Int,
                roomCode: data["roomCode"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
            
            self?.currentUser = user
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func generateRoomCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    func joinRoom(roomCode: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🚪 User attempting to join room: \(roomCode)")
        
        // Find the room with this code
        let snapshot = try await database.collection("rooms")
            .whereField("code", isEqualTo: roomCode)
            .limit(to: 1)
            .getDocuments()
        
        guard let roomDoc = snapshot.documents.first else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Room not found with code: \(roomCode)"])
        }
        
        print("✅ Found room: \(roomDoc.documentID)")
        
        // Update the room to add father's user ID
        try await database.collection("rooms").document(roomDoc.documentID).updateData([
            "fatherUserId": userId
        ])
        
        print("✅ Updated room with father's user ID")
        
        // Update user's roomCode
        try await database.collection("users").document(userId).updateData([
            "roomCode": roomCode
        ])
        
        print("✅ Updated user's room code")
    }
    
}
