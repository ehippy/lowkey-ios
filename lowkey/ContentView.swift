//
//  ContentView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [lowkeyPerson]
    @State private var showingAddPerson = false
    @State private var personToDelete: lowkeyPerson?
    @State private var showingDeleteConfirmation = false
    @StateObject private var notificationMonitor = InAppNotificationMonitor.shared
    @State private var showingUpcomingNotifications = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(people) { person in
                    NavigationLink {
                        PersonDetailView(person: person)
                    } label: {
                        HStack(spacing: 12) {
                            if let photo = person.photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.name)
                                    .font(.headline)
                                Text("\(person.relationshipType.displayName) • \(person.nudgeFrequency.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: requestDeleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addPerson) {
                        Label("Add Person", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack(spacing: 20) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Select a person")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Choose someone from the list to view their details")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonView()
        }
        .alert("Delete Person", isPresented: $showingDeleteConfirmation, presenting: personToDelete) { person in
            Button("Delete", role: .destructive) {
                deletePersonConfirmed(person)
            }
            Button("Cancel", role: .cancel) {
                personToDelete = nil
            }
        } message: { person in
            Text("Are you sure you want to delete \(person.name)? This action cannot be undone.")
        }
        .overlay(alignment: .top) {
            if let notification = notificationMonitor.currentNotification {
                InAppNotificationBanner(
                    notification: notification,
                    onDismiss: {
                        notificationMonitor.dismissCurrentNotification()
                    },
                    onTap: {
                        // Find the person and navigate to their detail view
                        if let person = people.first(where: { $0.id == notification.personId }) {
                            // TODO: Navigate to PersonDetailView
                            // For now, just dismiss the notification
                            notificationMonitor.dismissCurrentNotification()
                        }
                    }
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: notificationMonitor.currentNotification)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !notificationMonitor.upcomingNotifications.isEmpty {
                    Button {
                        showingUpcomingNotifications = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.badge")
                            Text("\(notificationMonitor.upcomingNotifications.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpcomingNotifications) {
            UpcomingNotificationsSheet(
                notifications: notificationMonitor.upcomingNotifications,
                isPresented: $showingUpcomingNotifications
            )
        }
        .onAppear {
            notificationMonitor.startMonitoring(people: people)
        }
        .onDisappear {
            notificationMonitor.stopMonitoring()
        }
    }

    private func addPerson() {
        showingAddPerson = true
    }

    private func requestDeleteItems(offsets: IndexSet) {
        guard let index = offsets.first else { return }
        personToDelete = people[index]
        showingDeleteConfirmation = true
    }

    private func deletePersonConfirmed(_ person: lowkeyPerson) {
        // Cancel notifications for this person
        NotificationManager.shared.cancelNotifications(for: person)
        
        withAnimation {
            modelContext.delete(person)
        }
        personToDelete = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: lowkeyPerson.self, inMemory: true)
}
