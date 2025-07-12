//
//  lowkeyApp.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/6/25.
//

import SwiftUI
import SwiftData

@main
struct lowkeyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            lowkeyPerson.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Refresh notifications when app becomes active
                refreshNotificationsWhenActive()
            }
        }
    }
    
    private func refreshNotificationsWhenActive() {
        Task {
            await performFreshNotificationRefresh()
        }
    }
    
    private func performFreshNotificationRefresh() async {
        print("🔄 App became active - starting fresh notification refresh...")
        
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<lowkeyPerson>()
        
        do {
            let people = try context.fetch(descriptor)
            print("📊 Found \(people.count) people for fresh refresh")
            await NotificationManager.shared.refreshAllNotifications(people)
        } catch {
            print("❌ Error fetching people for refresh: \(error)")
        }
    }
}
