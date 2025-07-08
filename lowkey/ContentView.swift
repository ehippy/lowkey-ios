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

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(people) { person in
                    NavigationLink {
                        PersonDetailView(person: person)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.name)
                                .font(.headline)
                            Text(person.relationshipType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
    }

    private func addPerson() {
        showingAddPerson = true
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
