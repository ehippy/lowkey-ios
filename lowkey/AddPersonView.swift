//
//  AddPersonView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI
import SwiftData

struct AddPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var relationshipType: RelationshipType = .friend
    @State private var nudgeFrequency: NudgeFrequency = .weekly
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Person Details")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Relationship")) {
                    Picker("Relationship Type", selection: $relationshipType) {
                        ForEach(RelationshipType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Mindfulness Frequency")) {
                    Picker("How often would you like to be reminded to reach out?", selection: $nudgeFrequency) {
                        ForEach(NudgeFrequency.allCases) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Text("You'll receive gentle reminders to check in with \(name.isEmpty ? "this person" : name) \(nudgeFrequency.displayName.lowercased()).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePerson()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func savePerson() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newPerson = lowkeyPerson(
            name: trimmedName,
            relationshipType: relationshipType,
            nudgeFrequency: nudgeFrequency
        )
        
        modelContext.insert(newPerson)
        
        // Trigger fresh notification refresh for all people
        Task {
            await triggerFreshNotificationRefresh()
        }
        
        dismiss()
    }
    
    private func triggerFreshNotificationRefresh() async {
        let descriptor = FetchDescriptor<lowkeyPerson>()
        do {
            let people = try modelContext.fetch(descriptor)
//            await NotificationManager.refreshAllNotifications(people)
        } catch {
            print("❌ Error fetching people for notification refresh: \(error)")
        }
    }
}

#Preview {
    AddPersonView()
        .modelContainer(for: lowkeyPerson.self, inMemory: true)
}
