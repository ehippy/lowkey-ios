//
//  EditPersonView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI
import SwiftData

struct EditPersonView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var person: lowkeyPerson
    
    @State private var name: String
    @State private var relationshipType: RelationshipType
    @State private var nudgeFrequency: NudgeFrequency
    
    init(person: lowkeyPerson) {
        self.person = person
        self._name = State(initialValue: person.name)
        self._relationshipType = State(initialValue: person.relationshipType)
        self._nudgeFrequency = State(initialValue: person.nudgeFrequency)
    }
    
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
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        person.name = trimmedName
        person.relationshipType = relationshipType
        person.nudgeFrequency = nudgeFrequency
        
        dismiss()
    }
}

#Preview {
    EditPersonView(person: lowkeyPerson(
        name: "John Doe",
        relationshipType: .friend,
        nudgeFrequency: .weekly
    ))
    .modelContainer(for: lowkeyPerson.self, inMemory: true)
}
