//
//  GuestDummyDataGenerator.swift
//  Tiny
//
//  Created for offline guest mode demonstration
//

import Foundation
import SwiftData
import UIKit

/// Generates dummy heartbeats and moments for offline guest fathers
@MainActor
class GuestDummyDataGenerator {
    
    /// Generates dummy heartbeat recordings for demonstration
    static func generateDummyHeartbeats(modelContext: ModelContext, pregnancyWeeks: Int) {
        print("🎭 Generating dummy heartbeats for guest mode...")
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate pregnancy start date based on current week
        guard let pregnancyStartDate = calendar.date(byAdding: .weekOfYear, value: -pregnancyWeeks, to: now) else {
            return
        }
        
        // Store pregnancy start date
        UserDefaults.standard.set(pregnancyStartDate, forKey: "pregnancyStartDate")
        UserDefaults.standard.set(pregnancyWeeks, forKey: "initialPregnancyWeek")
        
        // Generate heartbeats for the last 3 weeks
        let weeksToGenerate = [pregnancyWeeks - 2, pregnancyWeeks - 1, pregnancyWeeks]
        
        for week in weeksToGenerate {
            guard week > 0 else { continue }
            
            // Calculate date for this week
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: week - pregnancyWeeks, to: now) else {
                continue
            }
            
            // Generate 2-3 heartbeats per week
            let heartbeatCount = Int.random(in: 2...3)
            
            for iteration in 0..<heartbeatCount {
                // Spread heartbeats across the week
                let dayOffset = Double(iteration) * (7.0 / Double(heartbeatCount))
                guard let heartbeatDate = calendar.date(byAdding: .day, value: Int(dayOffset), to: weekDate) else {
                    continue
                }
                
                // Create dummy heartbeat with placeholder file path
                let heartbeat = SavedHeartbeat(
                    filePath: "/dummy/heartbeat_week\(week)_\(iteration).caf",
                    timestamp: heartbeatDate,
                    motherUserId: "guest_mother",
                    roomCode: "GUEST-DAD", // Father's room code
                    isShared: true,
                    firebaseStorageURL: nil,
                    pregnancyWeeks: week,
                    isSyncedToCloud: false,
                    firebaseId: nil
                )
                
                heartbeat.displayName = "Week \(week) Recording \(iteration + 1)"
                
                modelContext.insert(heartbeat)
                print("   ✅ Created dummy heartbeat: Week \(week), Recording \(iteration + 1)")
            }
        }
        
        // Save all heartbeats
        do {
            try modelContext.save()
            print("✅ Dummy heartbeats saved successfully")
        } catch {
            print("❌ Error saving dummy heartbeats: \(error)")
        }
    }
    
    /// Generates dummy moment images for demonstration
    static func generateDummyMoments(modelContext: ModelContext, pregnancyWeeks: Int) {
        print("🎭 Generating dummy moments for guest mode...")
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate moments for the last 2 weeks
        let weeksToGenerate = [pregnancyWeeks - 1, pregnancyWeeks]
        
        for week in weeksToGenerate {
            guard week > 0 else { continue }
            
            // Calculate date for this week
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: week - pregnancyWeeks, to: now) else {
                continue
            }
            
            // Generate 1-2 moments per week
            let momentCount = Int.random(in: 1...2)
            
            for iteration in 0..<momentCount {
                // Spread moments across the week
                let dayOffset = Double(iteration) * (7.0 / Double(momentCount))
                guard let momentDate = calendar.date(byAdding: .day, value: Int(dayOffset), to: weekDate) else {
                    continue
                }
                
                // Create a placeholder image
                let imageName = createDummyMomentImage(week: week, index: iteration)
                
                // Create dummy moment
                let moment = SavedMoment(
                    filePath: imageName,
                    timestamp: momentDate,
                    pregnancyWeeks: week,
                    firebaseId: nil,
                    motherUserId: "guest_mother",
                    roomCode: "GUEST-DAD", // Father's room code
                    isShared: true,
                    firebaseStorageURL: nil,
                    isSyncedToCloud: false
                )
                
                modelContext.insert(moment)
                print("   ✅ Created dummy moment: Week \(week), Moment \(iteration + 1)")
            }
        }
        
        // Save all moments
        do {
            try modelContext.save()
            print("✅ Dummy moments saved successfully")
        } catch {
            print("❌ Error saving dummy moments: \(error)")
        }
    }
    
    /// Creates a placeholder image for dummy moments
    private static func createDummyMomentImage(week: Int, index: Int) -> String {
        // Use portrait aspect ratio (3:4) like typical photos
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Simple solid color background with soft gradient
            let colors = [
                UIColor(red: 0.95, green: 0.85, blue: 0.95, alpha: 1.0).cgColor,
                UIColor(red: 0.85, green: 0.75, blue: 0.90, alpha: 1.0).cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                                start: CGPoint(x: 0, y: 0),
                                                end: CGPoint(x: size.width, y: size.height),
                                                options: [])
            
            // Add centered text with proper paragraph style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let titleText = "Week \(week)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let subtitleText = "Moment \(index + 1)"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: paragraphStyle
            ]
            
            // Calculate vertical center
            let spacing: CGFloat = 8
            let titleHeight = titleText.boundingRect(
                with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            ).height
            
            let subtitleHeight = subtitleText.boundingRect(
                with: CGSize(width: size.width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: subtitleAttributes,
                context: nil
            ).height
            
            let totalHeight = titleHeight + spacing + subtitleHeight
            let startY = (size.height - totalHeight) / 2
            
            // Draw text centered horizontally across full width
            let titleRect = CGRect(x: 0, y: startY, width: size.width, height: titleHeight)
            let subtitleRect = CGRect(x: 0, y: startY + titleHeight + spacing, width: size.width, height: subtitleHeight)
            
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            subtitleText.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        }
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "guest_moment_week\(week)_\(index).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
        
        return fileName
    }
    
    /// Checks if dummy data has already been generated for current session
    static func hasDummyData(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<SavedHeartbeat>(
            predicate: #Predicate { heartbeat in
                heartbeat.motherUserId == "guest_mother"
            }
        )
        
        do {
            let heartbeats = try modelContext.fetch(descriptor)
            return !heartbeats.isEmpty
        } catch {
            return false
        }
    }
}
