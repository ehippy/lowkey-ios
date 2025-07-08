//
//  EditPersonView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditPersonView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var person: lowkeyPerson
    
    @State private var name: String
    @State private var relationshipType: RelationshipType
    @State private var nudgeFrequency: NudgeFrequency
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    init(person: lowkeyPerson) {
        self.person = person
        self._name = State(initialValue: person.name)
        self._relationshipType = State(initialValue: person.relationshipType)
        self._nudgeFrequency = State(initialValue: person.nudgeFrequency)
        self._profileImage = State(initialValue: person.photo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo")) {
                    HStack {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            PhotosPicker("Choose Photo", selection: $selectedPhoto, matching: .images)
                                .foregroundColor(.blue)
                            
                            if profileImage != nil {
                                Button("Remove Photo") {
                                    profileImage = nil
                                    selectedPhoto = nil
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
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
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            profileImage = image
                        }
                    }
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
        person.setPhoto(profileImage)
        
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
