//
//  Item.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/6/25.
//

import Foundation
import SwiftData
import UIKit

@Model
class lowkeyPerson {
    var id: UUID
    var name: String
    var relationshipType: RelationshipType
    var nudgeFrequency: NudgeFrequency
    var photoData: Data?
    var lastNudgeDate: Date?
    var nudgeHistory: [Date]

    init(name: String,
         relationshipType: RelationshipType,
         nudgeFrequency: NudgeFrequency,
         photoData: Data? = nil,
         nudgeHistory: [Date] = []) {
        self.id = UUID()
        self.name = name
        self.relationshipType = relationshipType
        self.nudgeFrequency = nudgeFrequency
        self.photoData = photoData
        self.lastNudgeDate = nil // Will be set when first notification is scheduled
        self.nudgeHistory = nudgeHistory
    }
}

// MARK: - Photo Helpers
extension lowkeyPerson {
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    func setPhoto(_ image: UIImage?) {
        if let image = image {
            // Resize image to reasonable size to save storage
            let maxSize: CGFloat = 300
            let resizedImage = image.resized(to: maxSize)
            self.photoData = resizedImage.jpegData(compressionQuality: 0.8)
        } else {
            self.photoData = nil
        }
    }
}

extension UIImage {
    func resized(to maxSize: CGFloat) -> UIImage {
        let size = self.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 {
            return self
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// MARK: - Nudge Timing Helpers
extension lowkeyPerson {
    /// Calculate when the next nudge should occur based on frequency and last nudge
    var nextNudgeDate: Date {
        let calendar = Calendar.current
        let baseDate = lastNudgeDate ?? Date() // If never nudged, start from now
        
        switch nudgeFrequency {
        case .fewPerDay:
            // Every 4-8 hours
            return calendar.date(byAdding: .hour, value: 6, to: baseDate) ?? Date()
        case .daily:
            // Once per day
            return calendar.date(byAdding: .day, value: 1, to: baseDate) ?? Date()
        case .alternateDays:
            // Every other day
            return calendar.date(byAdding: .day, value: 2, to: baseDate) ?? Date()
        case .fewPerWeek:
            // Every 2-3 days
            return calendar.date(byAdding: .day, value: 3, to: baseDate) ?? Date()
        case .weekly:
            // Once per week
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? Date()
        case .monthly:
            // Once per month
            return calendar.date(byAdding: .month, value: 1, to: baseDate) ?? Date()
        case .quarterly:
            // Once per quarter
            return calendar.date(byAdding: .month, value: 3, to: baseDate) ?? Date()
        }
    }
    
    /// Check if this person is due for a nudge
    var isDueForNudge: Bool {
        return Date() >= nextNudgeDate
    }
    
    /// How many hours/days until next nudge
    var timeUntilNextNudge: String {
        let timeInterval = nextNudgeDate.timeIntervalSince(Date())
        
        if timeInterval <= 0 {
            return "Due now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hr"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    /// Mark that this person was nudged (call when notification fires or user manually reaches out)
    func markAsNudged() {
        lastNudgeDate = Date()
        if !nudgeHistory.contains(where: { Calendar.current.isDate($0, inSameDayAs: Date()) }) {
            nudgeHistory.append(Date())
        }
    }
    
    /// Returns a calendar-day-deduplicated history of nudge dates, newest first.
    private var deduplicatedNudgeHistory: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        var seenDays: [Date] = []
        var result: [Date] = []
        
        // Sort history descending
        let sorted = nudgeHistory.sorted { $0 > $1 }
        for date in sorted {
            let day = Calendar.current.startOfDay(for: date)
            if !seenDays.contains(day) {
                seenDays.append(day)
                result.append(date)
            }
            if seenDays.count >= 365 { break } // Cap at 1 year of unique days
        }
        return result
    }
    
    /// Current streak: consecutive calendar days ending today or yesterday.
    var currentStreak: Int {
        let deduped = deduplicatedNudgeHistory
        guard !deduped.isEmpty else { return 0 }
        
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let mostRecentDay = Calendar.current.startOfDay(for: deduped[0])
        
        // Streak must end today or yesterday to be current
        guard mostRecentDay == today || mostRecentDay == yesterday else { return 0 }
        
        var streak = 1
        for i in 1..<deduped.count {
            let currentDay = Calendar.current.startOfDay(for: deduped[i])
            let prevDay = Calendar.current.startOfDay(for: deduped[i - 1])
            let expectedDay = Calendar.current.date(byAdding: .day, value: -1, to: prevDay)!
            if currentDay == expectedDay {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    /// The longest single streak ever recorded (in consecutive calendar days).
    var longestStreak: Int {
        let deduped = deduplicatedNudgeHistory
        guard !deduped.isEmpty else { return 0 }
        
        let days = deduped.map { Calendar.current.startOfDay(for: $0) }.sorted(by: >)
        
        var longest = 1
        var current = 1
        
        for i in 1..<days.count {
            let expectedPrev = Calendar.current.date(byAdding: .day, value: -1, to: days[i - 1])!
            if days[i] == expectedPrev {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
    
    /// Human-readable streak description.
    var streakDescription: String {
        let current = currentStreak
        let longest = longestStreak
        
        if current == 0 {
            if longest > 0 {
                return "🏆 Best streak: \(longest) day\(longest == 1 ? "" : "s")"
            }
            return "🌱 No streak yet — start nudging!"
        }
        
        var desc = "🔥 Current streak: \(current) day\(current == 1 ? "" : "s")"
        if longest > current {
            desc += " (best: \(longest))"
        }
        return desc
    }
}
