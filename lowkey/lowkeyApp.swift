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
    }
}
