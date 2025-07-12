//
//  NotificationManager.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        print("🔔 Requesting notification permissions...")
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleNotifications(for person: lowkeyPerson) {
        print("📅 Starting to schedule notifications for \(person.name) (ID: \(person.id.uuidString))")
        print("📅 Frequency: \(person.nudgeFrequency.displayName)")
        
        // Cancel existing notifications for this person
        cancelNotifications(for: person)
        
        // Use smart scheduling that considers last nudge date
        let scheduleDates = getSmartScheduleDates(for: person)
        print("📅 Generated \(scheduleDates.count) smart notification dates")
        
        if scheduleDates.isEmpty {
            print("⚠️ No notifications needed for \(person.name) in the next 2 days")
            return
        }
        
        var successCount = 0
        var errorCount = 0
        
        for (index, date) in scheduleDates.enumerated() {
            let identifier = "\(person.id.uuidString)-\(index)"
            
            let content = UNMutableNotificationContent()
            content.title = "💝 Lowkey"
            content.body = "Time to reach out to \(person.name)"
            content.sound = .default
            content.userInfo = ["personId": person.id.uuidString]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                repeats: false
            )
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            print("📅 Scheduling notification \(index + 1)/\(scheduleDates.count) for \(date.formatted(date: .abbreviated, time: .shortened))")
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification \(identifier): \(error.localizedDescription)")
                    errorCount += 1
                } else {
                    print("✅ Successfully scheduled notification \(identifier)")
                    successCount += 1
                }
                
                // Log summary when all notifications are processed
                if successCount + errorCount == scheduleDates.count {
                    print("📅 Completed scheduling for \(person.name): \(successCount) successful, \(errorCount) errors")
                }
            }
        }
        
        // Update the last nudge date to now since we're scheduling notifications
        // (This represents when we "nudged" them by setting up the notifications)
        if !scheduleDates.isEmpty {
            person.lastNudgeDate = Date()
        }
    }
    
    func cancelNotifications(for person: lowkeyPerson) {
        print("🗑️ Canceling existing notifications for \(person.name) (ID: \(person.id.uuidString))")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(person.id.uuidString) }
            
            print("🗑️ Found \(identifiersToCancel.count) existing notifications to cancel")
            
            if !identifiersToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                print("✅ Canceled \(identifiersToCancel.count) notifications for \(person.name)")
            } else {
                print("ℹ️ No existing notifications found for \(person.name)")
            }
        }
    }
    
    /// Smart scheduling that considers when person was last nudged
    private func getSmartScheduleDates(for person: lowkeyPerson) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []
        
        // Default notification time: 10 AM
        let notificationHour = 10
        
        // Calculate when the next nudge should be based on their last nudge
        let nextNudgeDate = person.nextNudgeDate
        
        print("📅 \(person.name): Last nudged \(person.lastNudgeDate?.formatted() ?? "never"), next due \(nextNudgeDate.formatted())")
        
        // Only schedule notifications from the next due date forward, within our 2-day window
        let twoDaysFromNow = calendar.date(byAdding: .day, value: 2, to: now) ?? now
        
        // If they're not due until after our 2-day window, don't schedule anything
        if nextNudgeDate > twoDaysFromNow {
            print("📅 \(person.name): Next nudge (\(nextNudgeDate.formatted())) is beyond 2-day window")
            return []
        }
        
        // If they're due now or in the past, start scheduling from now
        let startDate = max(nextNudgeDate, now)
        
        switch person.nudgeFrequency {
        case .fewPerDay:
            // Schedule every 6-8 hours from the start date
            var currentDate = startDate
            while currentDate <= twoDaysFromNow && dates.count < 6 {
                if let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: currentDate),
                   scheduledDate > now {
                    dates.append(scheduledDate)
                }
                currentDate = calendar.date(byAdding: .hour, value: 8, to: currentDate) ?? currentDate
            }
            
        case .daily:
            // Schedule once per day from start date
            if let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: startDate),
               scheduledDate > now {
                dates.append(scheduledDate)
            }
            // Maybe one more if it's within the 2-day window
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: startDate),
               nextDay <= twoDaysFromNow,
               let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: nextDay) {
                dates.append(scheduledDate)
            }
            
        case .alternateDays:
            // Schedule for the start date if it's due
            if startDate <= now.addingTimeInterval(86400), // Within next day
               let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: startDate),
               scheduledDate > now {
                dates.append(scheduledDate)
            }
            
        case .fewPerWeek:
            // Schedule if it's a Monday, Wednesday, or Friday and within window
            let weekday = calendar.component(.weekday, from: startDate)
            if [2, 4, 6].contains(weekday), // Mon, Wed, Fri
               let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: startDate),
               scheduledDate > now {
                dates.append(scheduledDate)
            }
            
        case .weekly, .monthly, .quarterly:
            // Schedule once if due within the window
            if startDate <= twoDaysFromNow,
               let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: startDate),
               scheduledDate > now {
                dates.append(scheduledDate)
            }
        }
        
        return dates
    }
    
    // MARK: - Debug and Enumeration Methods
    
    func getAllPendingNotifications() async -> [UNNotificationRequest] {
        print("📋 Fetching all pending notifications...")
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("📋 Found \(requests.count) total pending notifications")
        return requests
    }
    
    func getNotificationsForPerson(_ person: lowkeyPerson) async -> [UNNotificationRequest] {
        print("📋 Fetching notifications for \(person.name)...")
        let allRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let personRequests = allRequests.filter { $0.identifier.hasPrefix(person.id.uuidString) }
        print("📋 Found \(personRequests.count) notifications for \(person.name)")
        return personRequests
    }
    
    func getUpcomingNotificationsForPerson(_ person: lowkeyPerson) async -> [(date: Date, content: String)] {
        print("📋 Getting upcoming notifications for \(person.name)...")
        let requests = await getNotificationsForPerson(person)
        var notifications: [(date: Date, content: String)] = []
        
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate() {
                notifications.append((date: date, content: request.content.body))
            } else {
                print("⚠️ Could not get trigger date for notification \(request.identifier)")
            }
        }
        
        // Sort by date
        notifications.sort { $0.date < $1.date }
        print("📋 Returning \(notifications.count) upcoming notifications for \(person.name)")
        return notifications
    }
    
    func getNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let count = requests.count
        print("📊 Total pending notifications: \(count)")
        return count
    }
    
    func printAllNotifications() async {
        let requests = await getAllPendingNotifications()
        print("=== All Pending Notifications (\(requests.count)) ===")
        
        let sortedRequests = requests.sorted {
            let date1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
            let date2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
            return date1 < date2
        }
        
        for request in sortedRequests {
            let personId = String(request.identifier.prefix(36)) // UUID length
            let triggerDate = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            
            print("ID: \(request.identifier)")
            print("Person: \(personId)")
            print("Title: \(request.content.title)")
            print("Body: \(request.content.body)")
            print("Scheduled: \(triggerDate?.formatted() ?? "Unknown")")
            print("---")
        }
    }
    
    // MARK: - Refresh Methods
    
    /// Universal refresh method - always cancels all notifications and reschedules from scratch
    func refreshAllNotifications(_ people: [lowkeyPerson]) async {
        print("🔄 Starting fresh notification refresh for \(people.count) people...")
        
        // Step 1: Cancel ALL notifications
        print("🗑️ Canceling all existing notifications...")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ All notifications canceled")
        
        // Step 2: Schedule notifications for all people using global prioritization
        await scheduleNotificationsForAllPeople(people)
    }
    
    /// Schedule notifications for all people with priority-based selection
    private func scheduleNotificationsForAllPeople(_ people: [lowkeyPerson]) async {
        var notificationCandidates: [(person: lowkeyPerson, date: Date, priority: Double)] = []
        
        // Generate all possible notifications
        for person in people {
            let dates = getSmartScheduleDates(for: person)
            let basePriority = getRelationshipPriority(person.relationshipType)
            let frequencyMultiplier = getFrequencyMultiplier(person.nudgeFrequency)
            let newPersonBoost = getNewPersonBoost(for: person)
            
            print("📊 \(person.name): \(dates.count) dates, priority \(basePriority), boost \(newPersonBoost)")
            
            // Special handling for never-nudged people
            if dates.isEmpty && person.lastNudgeDate == nil {
                print("🆕 \(person.name): Creating early notification for new person")
                let earlyDate = Calendar.current.date(byAdding: .hour, value: Int.random(in: 2...4), to: Date()) ?? Date()
                let urgencyScore = getUrgencyScore(for: earlyDate)
                let finalPriority = basePriority * frequencyMultiplier * newPersonBoost * urgencyScore
                notificationCandidates.append((person: person, date: earlyDate, priority: finalPriority))
            } else {
                for date in dates {
                    let urgencyScore = getUrgencyScore(for: date)
                    let finalPriority = basePriority * frequencyMultiplier * newPersonBoost * urgencyScore
                    notificationCandidates.append((person: person, date: date, priority: finalPriority))
                }
            }
        }
        
        // Sort by priority and take top 64
        let sortedCandidates = notificationCandidates.sorted { $0.priority > $1.priority }
        let topCandidates = Array(sortedCandidates.prefix(64))
        
        print("📊 Scheduling top \(topCandidates.count) notifications from \(notificationCandidates.count) candidates")
        
        // Schedule the selected notifications
        for (index, candidate) in topCandidates.enumerated() {
            let identifier = "\(candidate.person.id.uuidString)-\(index)"
            
            let content = UNMutableNotificationContent()
            content.title = "💝 Lowkey"
            content.body = "Time to reach out to \(candidate.person.name)"
            content.sound = .default
            content.userInfo = ["personId": candidate.person.id.uuidString]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: candidate.date),
                repeats: false
            )
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Scheduled notification for \(candidate.person.name) at \(candidate.date.formatted(date: .abbreviated, time: .shortened))")
            } catch {
                print("❌ Error scheduling notification: \(error)")
            }
        }
        
        // Update lastNudgeDate for people who got notifications
        let peopleWithNotifications = Set(topCandidates.map { $0.person.id })
        for person in people {
            if peopleWithNotifications.contains(person.id) {
                person.lastNudgeDate = Date()
            }
        }
        
        let finalCount = await getNotificationCount()
        print("🔄 Fresh refresh complete. Total notifications: \(finalCount)")
    }
    
    /// Calculate priority score based on relationship type
    private func getRelationshipPriority(_ type: RelationshipType) -> Double {
        switch type {
        case .romantic, .spouse: return 1.0
        case .parent, .child: return 0.9
        case .sibling: return 0.7
        case .friend: return 0.5
        case .other: return 0.3
        }
    }
    
    /// Calculate multiplier based on nudge frequency
    private func getFrequencyMultiplier(_ frequency: NudgeFrequency) -> Double {
        switch frequency {
        case .fewPerDay: return 1.0
        case .daily: return 0.8
        case .alternateDays: return 0.6
        case .fewPerWeek: return 0.4
        case .weekly: return 0.3
        case .monthly: return 0.2
        case .quarterly: return 0.1
        }
    }
    
    /// Calculate urgency score based on how soon the notification is due
    private func getUrgencyScore(for date: Date) -> Double {
        let timeInterval = date.timeIntervalSince(Date())
        let hoursUntil = timeInterval / 3600
        
        if hoursUntil <= 1 { return 1.0 }      // Due very soon
        if hoursUntil <= 6 { return 0.9 }      // Due today
        if hoursUntil <= 24 { return 0.7 }     // Due tomorrow
        return 0.5                              // Due later
    }
    
    /// Calculate new person boost - heavily prioritize people who have never been nudged
    private func getNewPersonBoost(for person: lowkeyPerson) -> Double {
        if person.lastNudgeDate == nil {
            return 2.0  // Double the priority for never-nudged people
        }
        return 1.0  // No boost for people who have been nudged before
    }
    
    // MARK: - Legacy Methods (keeping for backward compatibility)
    
    /// Legacy method - now just calls the unified refresh
    func refreshNotificationsForAllPeople(_ people: [lowkeyPerson]) {
        Task {
            await refreshAllNotifications(people)
        }
    }
}
