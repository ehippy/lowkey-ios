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

    init(name: String,
         relationshipType: RelationshipType,
         nudgeFrequency: NudgeFrequency,
         photoData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.relationshipType = relationshipType
        self.nudgeFrequency = nudgeFrequency
        self.photoData = photoData
        self.lastNudgeDate = nil // Will be set when first notification is scheduled
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
    }
}
