//
//  PersonDetailView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI
import UserNotifications

struct PersonDetailView: View {
    let person: lowkeyPerson
    @State private var showingEditView = false
    @State private var upcomingNotifications: [(date: Date, content: String)] = []
    @State private var isLoadingNotifications = true
    @State private var isNudging = false
    @State private var showNudgeConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if let photo = person.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(person.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(person.relationshipType.displayName)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mindfulness Frequency")
                    .font(.headline)
                
                Text("You'll be reminded to reach out \(person.nudgeFrequency.displayName.lowercased())")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Notifications")
                    .font(.headline)
                
                if isLoadingNotifications {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading notifications...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if upcomingNotifications.isEmpty {
                    Text("No upcoming notifications scheduled")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(upcomingNotifications.prefix(5).enumerated()), id: \.offset) { index, notification in
                            HStack {
                                Text(notification.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(notification.content)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 1)
                        }
                        
                        if upcomingNotifications.count > 5 {
                            Text("+ \(upcomingNotifications.count - 5) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Nudged")
                    .font(.headline)
                
                if let lastNudge = person.lastNudgeDate {
                    Text(lastNudge.formatted(date: .abbreviated, time: .shortened))
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never nudged — time to start!")
                        .font(.body)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
            
            // MARK: - Nudge Now Button
            Button {
                showNudgeConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Nudge Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            .confirmationDialog("Nudge \(person.name)?", isPresented: $showNudgeConfirmation, titleVisibility: .visible) {
                Button("Send Immediate Nudge", role: .none) {
                    Task {
                        isNudging = true
                        await NotificationManager.shared.immediateNudge(for: person)
                        await loadNotifications()
                        isNudging = false
                    }
                }
            } message: {
                Text("This will send a notification right away and reschedule future nudges.")
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView, onDismiss: {
            // Reload notifications when returning from edit view
            Task {
                await loadNotifications()
            }
        }) {
            EditPersonView(person: person)
        }
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        isLoadingNotifications = true
        upcomingNotifications = await NotificationManager.shared.getUpcomingNotificationsForPerson(person)
        isLoadingNotifications = false
    }
}

#Preview {
    NavigationView {
        PersonDetailView(person: lowkeyPerson(
            name: "John Doe",
            relationshipType: .friend,
            nudgeFrequency: .weekly
        ))
    }
}
