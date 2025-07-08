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
        
        // Schedule new notifications based on their frequency
        let scheduleDates = getScheduleDates(for: person.nudgeFrequency)
        print("📅 Generated \(scheduleDates.count) notification dates")
        
        if scheduleDates.isEmpty {
            print("⚠️ No future dates generated for \(person.name)")
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
    
    private func getScheduleDates(for frequency: NudgeFrequency) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []
        
        // Default notification time: 10 AM
        let notificationHour = 10
        
        // Only schedule for the next 2 days to stay well under the 64 notification limit
        let maxDays = 2
        
        switch frequency {
        case .fewPerDay:
            // 3 times a day for next 2 days only
            for day in 0..<maxDays {
                for hour in [9, 14, 19] { // 9 AM, 2 PM, 7 PM
                    if let date = calendar.date(byAdding: .day, value: day, to: now),
                       let scheduledDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date),
                       scheduledDate > now {
                        dates.append(scheduledDate)
                    }
                }
            }
            
        case .daily:
            // Once daily for next 2 days only
            for day in 1...maxDays {
                if let date = calendar.date(byAdding: .day, value: day, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
            
        case .alternateDays:
            // Every other day - check next 4 days to find up to 2 notifications
            for day in stride(from: 1, through: 4, by: 1) {
                if day % 2 == 0, // Only even days (alternate days)
                   let date = calendar.date(byAdding: .day, value: day, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date),
                   dates.count < 2 { // Limit to 2 notifications max
                    dates.append(scheduledDate)
                }
            }
            
        case .fewPerWeek:
            // 3 times per week (Mon, Wed, Fri) - only schedule for next 2 days
            for day in 1...maxDays {
                if let date = calendar.date(byAdding: .day, value: day, to: now) {
                    let weekday = calendar.component(.weekday, from: date)
                    // Monday = 2, Wednesday = 4, Friday = 6
                    if [2, 4, 6].contains(weekday),
                       let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                        dates.append(scheduledDate)
                    }
                }
            }
            
        case .weekly:
            // Once per week - only schedule if within next 2 days
            let dayOfWeek = calendar.component(.weekday, from: now)
            for day in 1...maxDays {
                if let date = calendar.date(byAdding: .day, value: day, to: now) {
                    let targetWeekday = calendar.component(.weekday, from: date)
                    if targetWeekday == dayOfWeek, // Same day of week as today
                       let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                        dates.append(scheduledDate)
                        break // Only one per week
                    }
                }
            }
            
        case .monthly:
            // Once per month - only schedule if the monthly date falls within next 2 days
            let dayOfMonth = calendar.component(.day, from: now)
            for day in 1...maxDays {
                if let date = calendar.date(byAdding: .day, value: day, to: now) {
                    let targetDayOfMonth = calendar.component(.day, from: date)
                    if targetDayOfMonth == dayOfMonth,
                       let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                        dates.append(scheduledDate)
                        break
                    }
                }
            }
            
        case .quarterly:
            // Once per quarter - very unlikely to fall within 2 days, but check anyway
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 0
            for day in 1...maxDays {
                if let date = calendar.date(byAdding: .day, value: day, to: now) {
                    let targetDayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
                    // Quarterly would be roughly every 90 days
                    if targetDayOfYear % 90 == dayOfYear % 90,
                       let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                        dates.append(scheduledDate)
                        break
                    }
                }
            }
        }
        
        // Return all dates (no artificial limit since we're only looking at 2 days)
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
