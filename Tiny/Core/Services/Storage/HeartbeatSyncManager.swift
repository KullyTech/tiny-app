//
//  HeartbeatSyncManager.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 27/11/25.
//

import Foundation
import FirebaseFirestore
import SwiftData
internal import Combine

@MainActor
class HeartbeatSyncManager: ObservableObject {
    private let dbf = Firestore.firestore()
    private let storageService = FirebaseStorageService()
    
    @Published var isSyncing = false
    @Published var syncError: String?
    
    // MARK: - Upload Heartbeat to Cloud
    
    /// Uploads a heartbeat recording to Firebase Storage and saves metadata to Firestore
    func uploadHeartbeat(
        _ heartbeat: SavedHeartbeat,
        motherUserId: String,
        roomCode: String
    ) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. Upload audio file to Firebase Storage
        let localURL = URL(fileURLWithPath: heartbeat.filePath)
        let heartbeatId = heartbeat.id.uuidString
        
        print("📤 Uploading heartbeat...")
        print("   Local path: \(localURL.path)")
        print("   Heartbeat ID: \(heartbeatId)")
        print("   Mother User ID: \(motherUserId)")
        print("   Room Code: \(roomCode)")
        print("   Is Shared: \(heartbeat.isShared)")
        
        let downloadURL = try await storageService.uploadHeartbeat(
            localFileURL: localURL,
            motherUserId: motherUserId,
            heartbeatId: heartbeatId
        )
        
        print("✅ Upload complete. Download URL: \(downloadURL)")
        
        // 2. Update local model
        heartbeat.firebaseStorageURL = downloadURL
        heartbeat.isSyncedToCloud = true
        heartbeat.motherUserId = motherUserId
        heartbeat.roomCode = roomCode
        // Keep the isShared value from the heartbeat (should be true by default)
        
        // 3. Save metadata to Firestore
        let metadata: [String: Any] = [
            "heartbeatId": heartbeatId,
            "motherUserId": motherUserId,
            "roomCode": roomCode,
            "firebaseStorageURL": downloadURL,
            "timestamp": Timestamp(date: heartbeat.timestamp),
            "isShared": heartbeat.isShared,  // Use the heartbeat's isShared value
            "pregnancyWeeks": heartbeat.pregnancyWeeks ?? 0,
            "createdAt": Timestamp(date: Date())
        ]
        
        print("💾 Saving metadata to Firestore...")
        print("   Metadata: \(metadata)")
        
        let docRef = try await dbf.collection("heartbeats").addDocument(data: metadata)
        heartbeat.firebaseId = docRef.documentID
        
        print("✅ Metadata saved to Firestore")
        print("   Document ID: \(docRef.documentID)")
        print("   Collection: heartbeats")
    }
    
    // MARK: - Share Heartbeat with Partner
    
    /// Marks a heartbeat as shared so the father can see it
    func shareHeartbeat(_ heartbeat: SavedHeartbeat) async throws {
        guard let firebaseId = heartbeat.firebaseId else {
            throw SyncError.notSynced
        }
        
        // Update Firestore
        try await dbf.collection("heartbeats").document(firebaseId).updateData([
            "isShared": true
        ])
        
        // Update local model
        heartbeat.isShared = true
    }
    
    // MARK: - Unshare Heartbeat
    
    /// Marks a heartbeat as not shared
    func unshareHeartbeat(_ heartbeat: SavedHeartbeat) async throws {
        guard let firebaseId = heartbeat.firebaseId else {
            throw SyncError.notSynced
        }
        
        // Update Firestore
        try await dbf.collection("heartbeats").document(firebaseId).updateData([
            "isShared": false
        ])
        
        // Update local model
        heartbeat.isShared = false
    }
    
    // MARK: - Fetch Shared Heartbeats (for fathers)
    
    /// Fetches all shared heartbeats for a specific room
    func fetchSharedHeartbeats(roomCode: String) async throws -> [HeartbeatMetadata] {
        print("🔍 Fetching heartbeats for room code: '\(roomCode)'")
        
        // Simplified query - only filter by roomCode, then filter isShared in code
        let snapshot = try await dbf.collection("heartbeats")
            .whereField("roomCode", isEqualTo: roomCode)
            .getDocuments()
        
        print("📊 Query returned \(snapshot.documents.count) documents")
        
        // Log all documents for debugging
        for (index, doc) in snapshot.documents.enumerated() {
            let data = doc.data()
            print("   Document \(index + 1):")
            print("      ID: \(doc.documentID)")
            print("      roomCode: \(data["roomCode"] as? String ?? "nil")")
            print("      isShared: \(data["isShared"] as? Bool ?? false)")
            print("      motherUserId: \(data["motherUserId"] as? String ?? "nil")")
            print("      storageURL: \(data["firebaseStorageURL"] as? String ?? "nil")")
        }
        
        // Filter and sort in code to avoid needing a composite index
        let heartbeats = snapshot.documents.compactMap { doc -> HeartbeatMetadata? in
            let data = doc.data()
            
            // Only include shared heartbeats
            guard let isShared = data["isShared"] as? Bool, isShared else {
                print("   ⚠️ Skipping document \(doc.documentID) - isShared is false or missing")
                return nil
            }
            
            let metadata = HeartbeatMetadata(
                id: doc.documentID,
                heartbeatId: data["heartbeatId"] as? String ?? "",
                motherUserId: data["motherUserId"] as? String ?? "",
                roomCode: data["roomCode"] as? String ?? "",
                firebaseStorageURL: data["firebaseStorageURL"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                isShared: isShared,
                pregnancyWeeks: data["pregnancyWeeks"] as? Int
            )
            
            print("   ✅ Including heartbeat: \(metadata.id)")
            return metadata
        }
        
        // Sort by timestamp descending (newest first)
        let sorted = heartbeats.sorted { $0.timestamp > $1.timestamp }
        print("📦 Returning \(sorted.count) shared heartbeats")
        return sorted
    }
    
    // MARK: - Fetch All Heartbeats for Room (for mothers)
    
    /// Fetches ALL heartbeats for a specific room (including non-shared)
    func fetchAllHeartbeatsForRoom(roomCode: String) async throws -> [HeartbeatMetadata] {
        print("🔍 Fetching ALL heartbeats for room code: '\(roomCode)'")
        
        let snapshot = try await dbf.collection("heartbeats")
            .whereField("roomCode", isEqualTo: roomCode)
            .getDocuments()
        
        print("📊 Query returned \(snapshot.documents.count) documents")
        
        let heartbeats = snapshot.documents.compactMap { doc -> HeartbeatMetadata? in
            let data = doc.data()
            
            return HeartbeatMetadata(
                id: doc.documentID,
                heartbeatId: data["heartbeatId"] as? String ?? "",
                motherUserId: data["motherUserId"] as? String ?? "",
                roomCode: data["roomCode"] as? String ?? "",
                firebaseStorageURL: data["firebaseStorageURL"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                isShared: data["isShared"] as? Bool ?? false,
                pregnancyWeeks: data["pregnancyWeeks"] as? Int
            )
        }
        
        let sorted = heartbeats.sorted { $0.timestamp > $1.timestamp }
        print("📦 Returning \(sorted.count) heartbeats")
        return sorted
    }
    
    // MARK: - Download Heartbeat (for fathers)

    /// Downloads a heartbeat audio file from Firebase Storage
    func downloadHeartbeat(metadata: HeartbeatMetadata) async throws -> URL {
        return try await storageService.downloadHeartbeat(
            downloadURL: metadata.firebaseStorageURL,
            heartbeatId: metadata.heartbeatId,
            timestamp: metadata.timestamp  // Pass the timestamp
        )
    }
    
    // MARK: - Delete Heartbeat
    
    /// Deletes a heartbeat from both Storage and Firestore
    func deleteHeartbeat(_ heartbeat: SavedHeartbeat) async throws {
        // Delete from Storage if synced
        if let storageURL = heartbeat.firebaseStorageURL {
            try await storageService.deleteHeartbeat(downloadURL: storageURL)
        }
        
        // Delete from Firestore
        if let firebaseId = heartbeat.firebaseId {
            try await dbf.collection("heartbeats").document(firebaseId).delete()
        }
    }
    
    // MARK: - Sync All Heartbeats from Cloud
    
    /// Syncs all heartbeats from Firestore and downloads missing audio files
    func syncHeartbeatsFromCloud(
        roomCode: String,
        modelContext: ModelContext,
        isMother: Bool = true
    ) async throws -> [SavedHeartbeat] {
        print("🔄 Syncing heartbeats from cloud...")
        print("   Room Code: \(roomCode)")
        print("   Is Mother: \(isMother)")
        
        // Fetch ALL heartbeats for the room (both mothers and fathers see everything)
        let metadataList = try await fetchAllHeartbeatsForRoom(roomCode: roomCode)
        
        print("📦 Found \(metadataList.count) heartbeats in cloud")
        
        var syncedHeartbeats: [SavedHeartbeat] = []
        
        for metadata in metadataList {
            print("   Processing heartbeat: \(metadata.id)")
            print("      Timestamp: \(metadata.timestamp)")
            print("      isShared: \(metadata.isShared)")
            print("      motherUserId: \(metadata.motherUserId)")
            
            // Check if we already have this heartbeat locally
            let allHeartbeats = try modelContext.fetch(FetchDescriptor<SavedHeartbeat>())
            let existingHeartbeat = allHeartbeats.first { $0.firebaseId == metadata.id }
            
            if let existing = existingHeartbeat {
                print("   ✅ Already have heartbeat: \(metadata.id)")
                print("      Local path: \(existing.filePath)")
                
                // Verify the file exists
                if FileManager.default.fileExists(atPath: existing.filePath) {
                    print("      ✅ File exists on disk")
                } else {
                    print("      ⚠️ File missing on disk, re-downloading...")
                    // Re-download if file is missing
                    do {
                        let localURL = try await downloadHeartbeat(metadata: metadata)
                        existing.filePath = localURL.path
                        print("      ✅ Re-downloaded to: \(localURL.path)")
                    } catch {
                        print("      ❌ Re-download failed: \(error)")
                    }
                }
                
                syncedHeartbeats.append(existing)
            } else {
                print("   📥 Downloading new heartbeat: \(metadata.id)")
                
                do {
                    let localURL = try await downloadHeartbeat(metadata: metadata)
                    print("      Downloaded to: \(localURL.path)")
                    
                    let heartbeat = SavedHeartbeat(
                        filePath: localURL.path,
                        timestamp: metadata.timestamp,
                        motherUserId: metadata.motherUserId,
                        roomCode: metadata.roomCode,
                        isShared: metadata.isShared,
                        firebaseStorageURL: metadata.firebaseStorageURL,
                        pregnancyWeeks: metadata.pregnancyWeeks,
                        isSyncedToCloud: true,
                        firebaseId: metadata.id
                    )
                    
                    modelContext.insert(heartbeat)
                    syncedHeartbeats.append(heartbeat)
                    print("   ✅ Saved heartbeat to SwiftData: \(metadata.id)")
                } catch {
                    print("   ❌ Failed to download heartbeat \(metadata.id): \(error)")
                }
            }
        }
        
        try modelContext.save()
        print("✅ Sync complete: \(syncedHeartbeats.count) heartbeats")
        
        return syncedHeartbeats
    }
}

// MARK: - Supporting Types

struct HeartbeatMetadata: Identifiable {
    let id: String
    let heartbeatId: String
    let motherUserId: String
    let roomCode: String
    let firebaseStorageURL: String
    let timestamp: Date
    let isShared: Bool
    let pregnancyWeeks: Int?
}

enum SyncError: LocalizedError {
    case notSynced
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .notSynced:
            return "Heartbeat has not been synced to cloud yet"
        case .uploadFailed:
            return "Failed to upload heartbeat"
        case .downloadFailed:
            return "Failed to download heartbeat"
        }
    }
}
