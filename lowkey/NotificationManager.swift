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
    
    /// Refresh notifications for all people when app becomes active
    func refreshNotificationsForAllPeople(_ people: [lowkeyPerson]) {
        print("🔄 Refreshing notifications for \(people.count) people...")
        
        Task {
            let currentCount = await getNotificationCount()
            print("📊 Current pending notifications: \(currentCount)")
            
            // If we're getting close to the limit, don't add more
            if currentCount >= 50 {
                print("⚠️ Too many pending notifications (\(currentCount)), skipping refresh")
                return
            }
            
            for person in people {
                await refreshNotificationsForPerson(person)
            }
            
            let finalCount = await getNotificationCount()
            print("🔄 Refresh complete. Total notifications: \(finalCount)")
        }
    }
    
    /// Check if a person needs more notifications and refresh if needed
    private func refreshNotificationsForPerson(_ person: lowkeyPerson) async {
        let upcomingNotifications = await getUpcomingNotificationsForPerson(person)
        let notificationsInNext2Days = upcomingNotifications.filter { notification in
            let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            return notification.date <= twoDaysFromNow
        }
        
        print("📊 \(person.name) has \(notificationsInNext2Days.count) notifications in next 2 days")
        
        // If they have fewer than expected for their frequency, refresh them
        let expectedMinimum = getExpectedNotificationsInTwoDays(for: person.nudgeFrequency)
        if notificationsInNext2Days.count < expectedMinimum {
            print("🔄 Refreshing notifications for \(person.name) (\(notificationsInNext2Days.count) < \(expectedMinimum))")
            scheduleNotifications(for: person)
        } else {
            print("✅ \(person.name) has sufficient notifications")
        }
    }
    
    /// Calculate how many notifications we expect for a frequency in a 2-day window
    private func getExpectedNotificationsInTwoDays(for frequency: NudgeFrequency) -> Int {
        switch frequency {
        case .fewPerDay:
            return 3 // At least 3 notifications (could be up to 6)
        case .daily:
            return 1 // At least 1 notification (could be 2)
        case .alternateDays:
            return 1 // Maybe 1 in 2 days
        case .fewPerWeek:
            return 1 // Roughly 1 every 2-3 days
        case .weekly:
            return 0 // Once per week, unlikely to have one in 2 days
        case .monthly:
            return 0 // Once per month, very unlikely
        case .quarterly:
            return 0 // Once per quarter, extremely unlikely
        }
    }
}
