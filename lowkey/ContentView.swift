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
