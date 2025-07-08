//
//  lowkeyTypes.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

enum RelationshipType: String, CaseIterable, Codable, Identifiable {
    case romantic
    case spouse
    case parent
    case child
    case friend
    case sibling
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .romantic: return "Romantic Partner"
        case .spouse: return "Spouse"
        case .parent: return "Parent"
        case .child: return "Child"
        case .friend: return "Friend"
        case .sibling: return "Sibling"
        case .other: return "Other"
        }
    }
}

enum NudgeFrequency: String, CaseIterable, Codable, Identifiable {
    case fewPerDay
    case daily
    case alternateDays
    case fewPerWeek
    case weekly
    case monthly
    case quarterly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fewPerDay: return "A Few Times a Day"
        case .daily: return "Daily"
        case .alternateDays: return "Every Other Day"
        case .fewPerWeek: return "A Few Times a Week"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        }
    }
}
