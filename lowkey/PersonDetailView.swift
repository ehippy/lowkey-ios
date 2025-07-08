//
//  PersonDetailView.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import SwiftUI

struct PersonDetailView: View {
    let person: lowkeyPerson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
