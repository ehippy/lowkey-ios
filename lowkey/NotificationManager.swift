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
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleNotifications(for person: lowkeyPerson) {
        // Cancel existing notifications for this person
        cancelNotifications(for: person)
        
        // Schedule new notifications based on their frequency
        let scheduleDates = getScheduleDates(for: person.nudgeFrequency)
        
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
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotifications(for person: lowkeyPerson) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(person.id.uuidString) }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    private func getScheduleDates(for frequency: NudgeFrequency) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []
        
        // Default notification time: 10 AM
        let notificationHour = 10
        
        switch frequency {
        case .fewPerDay:
            // 3 times a day for 14 days (42 notifications max)
            for day in 0..<14 {
                for hour in [9, 14, 19] { // 9 AM, 2 PM, 7 PM
                    if let date = calendar.date(byAdding: .day, value: day, to: now),
                       let scheduledDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date),
                       scheduledDate > now {
                        dates.append(scheduledDate)
                    }
                }
            }
            
        case .daily:
            // Once daily for 30 days
            for day in 1...30 {
                if let date = calendar.date(byAdding: .day, value: day, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
            
        case .alternateDays:
            // Every other day for 60 days
            for day in stride(from: 2, through: 60, by: 2) {
                if let date = calendar.date(byAdding: .day, value: day, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
            
        case .fewPerWeek:
            // 3 times per week (Mon, Wed, Fri) for 8 weeks
            for week in 0..<8 {
                for weekday in [2, 4, 6] { // Monday, Wednesday, Friday
                    if let date = calendar.date(byAdding: .weekOfYear, value: week, to: now),
                       let scheduledDate = calendar.date(bySetting: .weekday, value: weekday, of: date),
                       let finalDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: scheduledDate),
                       finalDate > now {
                        dates.append(finalDate)
                    }
                }
            }
            
        case .weekly:
            // Once per week for 20 weeks
            for week in 1...20 {
                if let date = calendar.date(byAdding: .weekOfYear, value: week, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
            
        case .monthly:
            // Once per month for 12 months
            for month in 1...12 {
                if let date = calendar.date(byAdding: .month, value: month, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
            
        case .quarterly:
            // Once per quarter for 2 years
            for quarter in 1...8 {
                if let date = calendar.date(byAdding: .month, value: quarter * 3, to: now),
                   let scheduledDate = calendar.date(bySettingHour: notificationHour, minute: 0, second: 0, of: date) {
                    dates.append(scheduledDate)
                }
            }
        }
        
        // Limit to 20 notifications per person to stay well under iOS's 64 limit
        return Array(dates.prefix(20))
    }
    
    // MARK: - Debug and Enumeration Methods
    
    func getAllPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    func getNotificationsForPerson(_ person: lowkeyPerson) async -> [UNNotificationRequest] {
        let allRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return allRequests.filter { $0.identifier.hasPrefix(person.id.uuidString) }
    }
    
    func getUpcomingNotificationsForPerson(_ person: lowkeyPerson) async -> [(date: Date, content: String)] {
        let requests = await getNotificationsForPerson(person)
        var notifications: [(date: Date, content: String)] = []
        
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate() {
                notifications.append((date: date, content: request.content.body))
            }
        }
        
        // Sort by date
        notifications.sort { $0.date < $1.date }
        return notifications
    }
    
    func getNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
}
