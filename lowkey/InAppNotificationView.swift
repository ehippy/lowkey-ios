//
//  InAppNotificationView.swift
//  lowkey
//
//  Visual component for in-app notifications
//

import SwiftUI

struct InAppNotificationBanner: View {
    let notification: InAppNotification
    let onDismiss: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(timeUntilString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.gradient)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .onTapGesture {
            onTap()
        }
    }
    
    private var timeUntilString: String {
        let timeInterval = notification.scheduledDate.timeIntervalSince(Date())
        
        if timeInterval <= 0 {
            return "Due now"
        }
        
        let minutes = Int(timeInterval / 60)
        
        if minutes < 1 {
            return "Due now"
        } else if minutes == 1 {
            return "Due in 1 minute"
        } else if minutes < 60 {
            return "Due in \(minutes) minutes"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "Due in 1 hour" : "Due in \(hours) hours"
        }
    }
}

struct UpcomingNotificationsSheet: View {
    let notifications: [InAppNotification]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                if notifications.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Nudges",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up! Check back later.")
                    )
                } else {
                    ForEach(notifications) { notification in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(notification.personName)
                                    .font(.headline)
                            }
                            
                            Text(notification.message)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text(notification.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Upcoming Nudges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        InAppNotificationBanner(
            notification: InAppNotification(
                personId: UUID(),
                personName: "Kathryn",
                message: "Hey, send Kathryn a little love ❤️",
                scheduledDate: Date().addingTimeInterval(300)
            ),
            onDismiss: {},
            onTap: {}
        )
        .padding()
        
        Spacer()
    }
}
