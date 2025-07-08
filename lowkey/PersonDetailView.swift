//
//  PersonDetailView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI

struct PersonDetailView: View {
    let person: lowkeyPerson
    @State private var showingEditView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if let photo = person.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(person.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(person.relationshipType.displayName)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mindfulness Frequency")
                    .font(.headline)
                
                Text("You'll be reminded to reach out \(person.nudgeFrequency.displayName.lowercased())")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditPersonView(person: person)
        }
    }
}

#Preview {
    NavigationView {
        PersonDetailView(person: lowkeyPerson(
            name: "John Doe",
            relationshipType: .friend,
            nudgeFrequency: .weekly
        ))
    }
}
