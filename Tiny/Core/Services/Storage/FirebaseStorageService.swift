//
//  FirebaseStorageService.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import Foundation
import FirebaseStorage
import FirebaseAuth
internal import Combine

@MainActor
class FirebaseStorageService: ObservableObject {
    private let storage = Storage.storage()
    
    // MARK: - Upload Heartbeat Audio
    
    /// Uploads an audio file to Firebase Storage
    /// - Parameters:
    ///   - localFileURL: Local file URL of the audio
    ///   - motherUserId: User ID of the mother
    ///   - heartbeatId: Unique ID for this heartbeat
    /// - Returns: Download URL of the uploaded file
    func uploadHeartbeat(
        localFileURL: URL,
        motherUserId: String,
        heartbeatId: String
    ) async throws -> String {
        // Create storage reference
        // Path: heartbeats/{motherUserId}/{heartbeatId}.caf (changed from .m4a)
        let storageRef = storage.reference()
        let heartbeatRef = storageRef.child("heartbeats/\(motherUserId)/\(heartbeatId).caf")
        
        // Read file data
        let data = try Data(contentsOf: localFileURL)
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-caf" // Changed from audio/m4a
        metadata.customMetadata = [
            "motherUserId": motherUserId,
            "heartbeatId": heartbeatId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Upload file
        _ = try await heartbeatRef.putDataAsync(data, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await heartbeatRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Download Heartbeat Audio
    
    /// Downloads an audio file from Firebase Storage
    /// - Parameters:
    ///   - downloadURL: Firebase Storage download URL
    ///   - heartbeatId: Unique ID for this heartbeat
    /// - Returns: Local file URL where the audio was saved
    /// Downloads an audio file from Firebase Storage
    /// - Parameters:
    ///   - downloadURL: Firebase Storage download URL
    ///   - heartbeatId: Unique ID for this heartbeat
    ///   - timestamp: Timestamp for the recording (for filename)
    /// - Returns: Local file URL where the audio was saved
    func downloadHeartbeat(
        downloadURL: String,
        heartbeatId: String,
        timestamp: Date
    ) async throws -> URL {
        guard URL(string: downloadURL) != nil else {
            throw StorageError.invalidURL
        }

        // Create local file path with timestamp-based name (matching original format)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timeInterval = timestamp.timeIntervalSince1970
        let fileName = "recording-\(timeInterval).caf"
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        // If file already exists, return it
        if FileManager.default.fileExists(atPath: localURL.path) {
            print("✅ File already exists locally: \(localURL.path)")
            return localURL
        }
        
        // Download file
        print("📥 Downloading from Firebase Storage...")
        print("   Download URL: \(downloadURL)")
        print("   Local path: \(localURL.path)")
        
        let storageRef = storage.reference(forURL: downloadURL)
        _ = try await storageRef.writeAsync(toFile: localURL)
        print("✅ Downloaded to: \(localURL.path)")
        
        return localURL
    }
    
    // MARK: - Delete Heartbeat Audio
    
    /// Deletes an audio file from Firebase Storage
    /// - Parameters:
    ///   - downloadURL: Firebase Storage download URL
    func deleteHeartbeat(downloadURL: String) async throws {
        let storageRef = storage.reference(forURL: downloadURL)
        try await storageRef.delete()
    }
    
    // MARK: - Upload Moment Image
    
    func uploadMomentImage(
        localFileURL: URL,
        motherUserId: String,
        momentId: String
    ) async throws -> String {
        let storageRef = storage.reference()
        let momentRef = storageRef.child("moments/\(motherUserId)/\(momentId).jpg")
        
        let data = try Data(contentsOf: localFileURL)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "motherUserId": motherUserId,
            "momentId": momentId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        _ = try await momentRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await momentRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Download Moment Image
    
    func downloadMomentImage(
        downloadURL: String,
        momentId: String,
        timestamp: Date
    ) async throws -> URL {
        guard URL(string: downloadURL) != nil else {
            throw StorageError.invalidURL
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timeInterval = timestamp.timeIntervalSince1970
        let fileName = "moment-\(timeInterval).jpg"
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        let storageRef = storage.reference(forURL: downloadURL)
        _ = try await storageRef.writeAsync(toFile: localURL)
        
        return localURL
    }
    
    // MARK: - Delete Moment Image
    
    func deleteMomentImage(downloadURL: String) async throws {
        let storageRef = storage.reference(forURL: downloadURL)
        try await storageRef.delete()
    }
    
    // MARK: - Get Shared Heartbeats for Room
    
    /// Lists all heartbeats shared in a room
    /// - Parameter roomCode: The room code
    /// - Returns: Array of storage references
    func listSharedHeartbeats(for motherUserId: String) async throws -> [StorageReference] {
        let storageRef = storage.reference()
        let heartbeatsRef = storageRef.child("heartbeats/\(motherUserId)")
        
        let result = try await heartbeatsRef.listAll()
        return result.items
    }
}

enum StorageError: LocalizedError {
    case invalidURL
    case uploadFailed
    case downloadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid storage URL"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        case .deleteFailed:
            return "Failed to delete file"
        }
    }
}
