//
//  AuthenticationService.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
internal import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
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
        
        let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
        
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
                pregnancyMonths: nil,
                roomCode: nil,
                createdAt: Date()
            )
            
            try db.collection("users").document(result.user.uid).setData(from: newUser)
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
    
    func updateUserRole(role: UserRole, pregnancyMonths: Int? = nil, roomCode: String? = nil) async throws {
        guard let userId = auth.currentUser?.uid else {
            return
        }
        
        var updateData: [String: Any] = ["role": role.rawValue]
        
        if role == .mother, let months = pregnancyMonths {
            updateData["pregnancyMonths"] = months
        }
        
        if role == .father, let code = roomCode, !code.isEmpty {
            updateData["roomCode"] = code
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
        fetchUserData(userId: userId)
    }
    
    func updateUserName(name: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            return
        }
        
        try await db.collection("users").document(userId).updateData(["name": name])
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
        
        let docRef = try db.collection("rooms").addDocument(from: room)
        
        try await db.collection("users").document(userId).updateData(["roomCode": roomCode])
        fetchUserData(userId: userId)
        
        return roomCode
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
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
                pregnancyMonths: data["pregnancyMonths"] as? Int,
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
    
    
    
}
