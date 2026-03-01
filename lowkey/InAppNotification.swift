//
//  InAppNotification.swift
//  lowkey
//
//  Manages in-app notification display when app is active
//

import Foundation
import SwiftUI

struct InAppNotification: Identifiable, Equatable {
    let id = UUID()
    let personId: UUID
    let personName: String
    let message: String
    let scheduledDate: Date
    
    static func == (lhs: InAppNotification, rhs: InAppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class InAppNotificationMonitor: ObservableObject {
    @Published var currentNotification: InAppNotification?
    @Published var upcomingNotifications: [InAppNotification] = []
    
    private var checkTimer: Timer?
    private let checkInterval: TimeInterval = 60 // Check every minute
    
    static let shared = InAppNotificationMonitor()
    
    private init() {}
    
    func startMonitoring(people: [lowkeyPerson]) {
        print("📱 Starting in-app notification monitoring...")
        
        // Initial check
        Task {
            await checkForNotifications(people: people)
        }
        
        // Set up timer for periodic checks
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNotifications(people: people)
            }
        }
    }
    
    func stopMonitoring() {
        print("📱 Stopping in-app notification monitoring")
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    func checkForNotifications(people: [lowkeyPerson]) async {
        let now = Date()
        var notifications: [InAppNotification] = []
        
        for person in people {
            let upcoming = await NotificationManager.shared.getUpcomingNotificationsForPerson(person)
            
            for (date, message) in upcoming {
                // Consider notifications due within the next 30 minutes
                let timeUntil = date.timeIntervalSince(now)
                if timeUntil >= 0 && timeUntil <= 1800 { // 30 minutes
                    notifications.append(InAppNotification(
                        personId: person.id,
                        personName: person.name,
                        message: message,
                        scheduledDate: date
                    ))
                }
            }
        }
        
        // Sort by scheduled date
        notifications.sort { $0.scheduledDate < $1.scheduledDate }
        
        upcomingNotifications = notifications
        
        // Show the most urgent notification (due within 5 minutes) if not already showing
        if let mostUrgent = notifications.first,
           mostUrgent.scheduledDate.timeIntervalSince(now) <= 300, // 5 minutes
           currentNotification?.id != mostUrgent.id {
            currentNotification = mostUrgent
            print("📱 Showing in-app notification for \(mostUrgent.personName)")
        }
    }
    
    func dismissCurrentNotification() {
        currentNotification = nil
    }
}
