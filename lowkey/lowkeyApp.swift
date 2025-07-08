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
        print("🔄 App became active - refreshing notifications...")
        
        // Get all people from the model container
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<lowkeyPerson>()
        
        do {
            let people = try context.fetch(descriptor)
            print("📊 Found \(people.count) people for notification refresh")
            NotificationManager.shared.refreshNotificationsForAllPeople(people)
        } catch {
            print("❌ Error fetching people for refresh: \(error)")
        }
    }
}
