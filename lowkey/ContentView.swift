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

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(people) { person in
                    NavigationLink {
                        Text(person.name)
                    } label: {
                        Text(person.name)
                    }
                }
                .onDelete(perform: deleteItems)
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
            Text("Select an item")
        }
    }

    private func addPerson() {
        
//        withAnimation {
//            let newPerson = lowkeyPerson()
//            modelContext.insert(newItem)
//        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(people[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: lowkeyPerson.self, inMemory: true)
}
