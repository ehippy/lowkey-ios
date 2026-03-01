//
//  NudgeContentGenerator.swift
//  lowkey
//
//  Generates personalized notification text for nudges
//

import Foundation

struct NudgeContent {
    let title: String
    let body: String
}

class NudgeContentGenerator {
    static let shared = NudgeContentGenerator()
    
    private init() {}
    
    /// Generate a nudge notification for a person
    func generateNudge(for person: lowkeyPerson) -> NudgeContent {
        let body = generateNudgeBody(for: person)
        return NudgeContent(title: "💝 Lowkey", body: body)
    }
    
    private func generateNudgeBody(for person: lowkeyPerson) -> String {
        // Get relationship-specific templates
        let templates = getTemplates(for: person.relationshipType)
        
        // Randomly select a template
        guard let template = templates.randomElement() else {
            return "Time to reach out to \(person.name)"
        }
        
        // Replace {name} placeholder
        return template.replacingOccurrences(of: "{name}", with: person.name)
    }
    
    private func getTemplates(for relationship: RelationshipType) -> [String] {
        switch relationship {
        case .romantic, .spouse:
            return [
                "Hey, send {name} a little love ❤️",
                "Check in with {name} 💕",
                "{name}'s been on your mind — reach out",
                "Time for a {name} moment 🌟",
                "Show {name} you're thinking of them",
                "{name} would love to hear from you",
                "Send {name} something sweet today",
                "Brighten {name}'s day with a message"
            ]
            
        case .parent:
            return [
                "Call your parent — {name}",
                "Check in on {name} today",
                "{name} would love to hear from you",
                "Time to call {name}",
                "Send {name} a message today",
                "{name}'s probably wondering how you are",
                "Catch up with {name}",
                "Give {name} a ring"
            ]
            
        case .child:
            return [
                "Check in with {name} today",
                "Send {name} something fun",
                "{name} would love a message from you",
                "How's {name} doing? Time to find out",
                "Reach out to {name}",
                "Send {name} a little love",
                "Time for a {name} check-in",
                "{name} moment — say hi"
            ]
            
        case .friend:
            return [
                "Say hi to {name} today",
                "{name} check-in time",
                "Send {name} a meme or something",
                "How's {name} been? Find out",
                "Reach out to {name}",
                "{name}'s probably been wondering about you",
                "Time to message {name}",
                "Send {name} something fun",
                "Drop {name} a line today"
            ]
            
        case .sibling:
            return [
                "Check in with {name}",
                "Send {name} a message today",
                "How's {name} doing?",
                "{name} time — reach out",
                "Say hi to {name}",
                "Catch up with {name}",
                "Send {name} something funny",
                "Time to bug {name} (nicely)"
            ]
            
        case .other:
            return [
                "Reach out to {name} today",
                "Check in with {name}",
                "{name} would love to hear from you",
                "Send {name} a message",
                "Time to say hi to {name}",
                "Catch up with {name}",
                "Drop {name} a line"
            ]
        }
    }
}
