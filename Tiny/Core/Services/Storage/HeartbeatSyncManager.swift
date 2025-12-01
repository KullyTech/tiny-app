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

// swiftlint:disable type_body_length
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
        var metadata: [String: Any] = [
            "heartbeatId": heartbeatId,
            "motherUserId": motherUserId,
            "roomCode": roomCode,
            "firebaseStorageURL": downloadURL,
            "timestamp": Timestamp(date: heartbeat.timestamp),
            "isShared": heartbeat.isShared,  // Use the heartbeat's isShared value
            "pregnancyWeeks": heartbeat.pregnancyWeeks ?? 0,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let displayName = heartbeat.displayName {
            metadata["displayName"] = displayName
        }
        
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
        isSyncing = true
        defer { isSyncing = false }
        
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
    
    // MARK: - Update Heartbeat Name
    
    /// Updates the display name of a heartbeat in Firestore
    func updateHeartbeatName(_ heartbeat: SavedHeartbeat, newName: String) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        guard let firebaseId = heartbeat.firebaseId else {
            throw SyncError.notSynced
        }
        
        print("📝 Updating heartbeat name in Firestore...")
        print("   ID: \(firebaseId)")
        print("   New Name: \(newName)")
        
        // Update Firestore
        try await dbf.collection("heartbeats").document(firebaseId).updateData([
            "displayName": newName
        ])
        
        // Update local model
        heartbeat.displayName = newName
        print("✅ Heartbeat name updated in Firestore")
    }
    
    // MARK: - Unshare Heartbeat
    
    /// Marks a heartbeat as not shared
    func unshareHeartbeat(_ heartbeat: SavedHeartbeat) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
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
                pregnancyWeeks: data["pregnancyWeeks"] as? Int,
                displayName: data["displayName"] as? String
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
                pregnancyWeeks: data["pregnancyWeeks"] as? Int,
                displayName: data["displayName"] as? String
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
        isSyncing = true
        defer { isSyncing = false }
        
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
        isSyncing = true
        defer { isSyncing = false }
        
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
                    
                    // Set display name if available
                    if let displayName = metadata.displayName {
                        heartbeat.displayName = displayName
                    }
                    
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

    // MARK: - Moment Sync
    
    func uploadMoment(
        _ moment: SavedMoment,
        motherUserId: String,
        roomCode: String
    ) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. Reconstruct full path from filename (since we store relative paths)
        let fileName = URL(fileURLWithPath: moment.filePath).lastPathComponent
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent(fileName)
        let momentId = moment.id.uuidString
        
        print("📤 Uploading moment...")
        print("   Local file: \(localURL.path)")
        
        let downloadURL = try await storageService.uploadMomentImage(
            localFileURL: localURL,
            motherUserId: motherUserId,
            momentId: momentId
        )
        
        // 2. Update local model
        moment.firebaseStorageURL = downloadURL
        moment.isSyncedToCloud = true
        moment.motherUserId = motherUserId
        moment.roomCode = roomCode
        
        // 3. Save metadata to Firestore
        let metadata: [String: Any] = [
            "momentId": momentId,
            "motherUserId": motherUserId,
            "roomCode": roomCode,
            "firebaseStorageURL": downloadURL,
            "timestamp": Timestamp(date: moment.timestamp),
            "isShared": moment.isShared,
            "pregnancyWeeks": moment.pregnancyWeeks ?? 0,
            "createdAt": Timestamp(date: Date())
        ]
        
        let docRef = try await dbf.collection("moments").addDocument(data: metadata)
        moment.firebaseId = docRef.documentID
        
        print("✅ Moment metadata saved to Firestore")
    }
    
    func deleteMoment(_ moment: SavedMoment) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // Delete from Storage if synced
        if let storageURL = moment.firebaseStorageURL {
            try await storageService.deleteMomentImage(downloadURL: storageURL)
        }
        
        // Delete from Firestore
        if let firebaseId = moment.firebaseId {
            try await dbf.collection("moments").document(firebaseId).delete()
        }
    }
    
    func fetchAllMomentsForRoom(roomCode: String) async throws -> [MomentMetadata] {
        print("🔍 Fetching ALL moments for room code: '\(roomCode)'")
        
        let snapshot = try await dbf.collection("moments")
            .whereField("roomCode", isEqualTo: roomCode)
            .getDocuments()
        
        let moments = snapshot.documents.compactMap { doc -> MomentMetadata? in
            let data = doc.data()
            
            return MomentMetadata(
                id: doc.documentID,
                momentId: data["momentId"] as? String ?? "",
                motherUserId: data["motherUserId"] as? String ?? "",
                roomCode: data["roomCode"] as? String ?? "",
                firebaseStorageURL: data["firebaseStorageURL"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                isShared: data["isShared"] as? Bool ?? false,
                pregnancyWeeks: data["pregnancyWeeks"] as? Int
            )
        }
        
        return moments.sorted { $0.timestamp > $1.timestamp }
    }
    
    func downloadMoment(metadata: MomentMetadata) async throws -> URL {
        return try await storageService.downloadMomentImage(
            downloadURL: metadata.firebaseStorageURL,
            momentId: metadata.momentId,
            timestamp: metadata.timestamp
        )
    }
    
    func syncMomentsFromCloud(
        roomCode: String,
        modelContext: ModelContext
    ) async throws -> [SavedMoment] {
        isSyncing = true
        defer { isSyncing = false }
        
        print("🔄 Syncing moments from cloud...")
        
        let metadataList = try await fetchAllMomentsForRoom(roomCode: roomCode)
        var syncedMoments: [SavedMoment] = []
        
        for metadata in metadataList {
            // Check if we already have this moment locally
            let allMoments = try modelContext.fetch(FetchDescriptor<SavedMoment>())
            let existingMoment = allMoments.first { $0.firebaseId == metadata.id }
            
            if let existing = existingMoment {
                // Fix: Check existence using filename only
                let storedPath = existing.filePath
                let fileName = URL(fileURLWithPath: storedPath).lastPathComponent
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let localURL = documentsPath.appendingPathComponent(fileName)
                
                if !FileManager.default.fileExists(atPath: localURL.path) {
                    // Re-download if file is missing
                    do {
                        let downloadedURL = try await downloadMoment(metadata: metadata)
                        // Update to relative path (filename)
                        existing.filePath = downloadedURL.lastPathComponent
                    } catch {
                        print("❌ Re-download moment failed: \(error)")
                    }
                } else {
                    // If file exists but path was absolute, update to relative for consistency
                    if existing.filePath != fileName {
                        existing.filePath = fileName
                    }
                }
                syncedMoments.append(existing)
            } else {
                // Download new moment
                do {
                    let localURL = try await downloadMoment(metadata: metadata)
                    
                    let moment = SavedMoment(
                        filePath: localURL.lastPathComponent, // Store relative path
                        timestamp: metadata.timestamp,
                        pregnancyWeeks: metadata.pregnancyWeeks,
                        firebaseId: metadata.id,
                        motherUserId: metadata.motherUserId,
                        roomCode: metadata.roomCode,
                        isShared: metadata.isShared,
                        firebaseStorageURL: metadata.firebaseStorageURL,
                        isSyncedToCloud: true
                    )
                    
                    modelContext.insert(moment)
                    syncedMoments.append(moment)
                    print("   ✅ Saved moment to SwiftData: \(metadata.id)")
                } catch {
                    print("   ❌ Failed to download moment \(metadata.id): \(error)")
                }
            }
        }
        
        try modelContext.save()
        print("✅ Moment sync complete: \(syncedMoments.count) moments")
        
        return syncedMoments
    }
}
// swiftlint:enable type_body_length

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
    let displayName: String?
}

struct MomentMetadata: Identifiable {
    let id: String
    let momentId: String
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
            return "Item has not been synced to cloud yet"
        case .uploadFailed:
            return "Failed to upload item"
        case .downloadFailed:
            return "Failed to download item"
        }
    }
}
