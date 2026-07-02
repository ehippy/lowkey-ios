//
//  NudgeContentGenerator.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/7/25.
//

import Foundation

/// Generates personalized, rotating notification messages for nudge reminders.
/// Each person gets a diverse set of messages that cycle through, so notifications
/// don't become repetitive over time.
struct NudgeContentGenerator {
    
    /// Message templates organized by relationship type for contextual relevance.
    /// Each relationship type has 6+ messages for rotation diversity.
    private static let messageTemplates: [RelationshipType: [String]] = [
        .romantic: [
            "💝 Take a moment to check in with your romantic partner",
            "💕 Your partner would love to hear from you right now",
            "💘 A quick message goes a long way with your love",
            "💋 Don't forget the one who makes your heart skip a beat",
            "💖 Reach out to your special someone — they're thinking of you",
            "🌹 Send some love to your romantic partner today",
            "💌 Your partner is worth the effort — say hello!",
            "✨ A moment of connection means the world to them"
        ],
        .spouse: [
            "💍 Your spouse is counting on your daily check-in",
            "💒 Take a breath and reach out to your life partner",
            "💞 A quick 'thinking of you' brightens their whole day",
            "💐 You two make a great team — stay connected",
            "💗 Your spouse loves hearing from you — don't keep them waiting",
            "🏠 Home is where your spouse is — send a little home energy",
            "💫 Life's better together — touch base with your person",
            "🤝 You and your spouse are an unstoppable duo"
        ],
        .parent: [
            "👨‍👧 Remember to call your parents — they'd love to hear from you",
            "🏡 Your parents are wondering how you're doing",
            "👴👵 A quick check-in means the world to your folks",
            "💙 Parents always want to know their kids are okay",
            "🌳 Family roots matter — reach out to your parents today",
            "👨‍👦 Your parents appreciate every message, big or small",
            "🍎 Take a moment for the people who took care of you first",
            "💌 Your parents' favorite notification is from you"
        ],
        .child: [
            "🧒 Your child is waiting to hear from you",
            "🌟 A quick message keeps your bond strong",
            "🎈 Kids thrive on knowing you're thinking of them",
            "💙 Don't let the day pass without checking in",
            "🌈 Your child would light up to hear from you",
            "👋 Even a brief 'how's it going' means everything",
            "⭐ You're their hero — give them a call",
            "🎒 Stay present in their life, one message at a time"
        ],
        .friend: [
            "👋 Your friend misses your energy — drop a line!",
            "🤗 Real friends check in — be that friend right now",
            "💬 A quick 'what's up?' keeps friendships alive",
            "🎯 Friendship needs tending — water yours today",
            "🌟 Your friend is thinking about you — think about them!",
            "🍻 Good friendships are worth the effort — reach out",
            "🤝 Keep the bond strong with a simple hello",
            "💡 The best time to reach out is always now"
        ],
        .sibling: [
            "👫 Your sibling needs you — send a quick message",
            "🏠 Family first — check in with your brother or sister",
            "💪 Siblings are built-in best friends — act like it",
            "👪 A quick text keeps the sibling bond alive",
            "🎯 You grew up together — stay connected now",
            "🤗 Your sibling would love to hear from you",
            "🧬 Blood runs deep — make them feel it today",
            "💙 Sibling love is special — don't take it for granted"
        ],
        .other: [
            "💭 Someone important is on your mind — reach out!",
            "🌟 Your connections matter — nurture them today",
            "💡 Don't let a meaningful relationship fade",
            "🤝 Every great connection started with a hello",
            "💬 The person you're thinking of wants to hear from you",
            "🌈 Stay connected to the people who matter",
            "📱 Put the phone to good use — check in with someone",
            "💭 Moments of reach-out create moments of connection"
        ]
    ]
    
    /// Default fallback messages used when no relationship-specific template is available.
    private static let defaultMessages: [String] = [
        "💭 It's time to reach out to someone special",
        "💝 Don't forget the people who make life better",
        "🤝 A quick check-in keeps connections alive",
        "🌟 Reach out to someone who's been on your mind",
        "💬 Your people are worth the effort",
        "📱 Put the phone to good use — say hello",
        "💭 Someone's waiting for your message",
        "🌈 Stay connected to the people who matter"
    ]
    
    /// Generates a personalized nudge message for a given person.
    /// Messages rotate based on the current hour so that repeated notifications
    /// throughout a day are different each time.
    static func generateMessage(for person: lowkeyPerson) -> String {
        let templates = messageTemplates[person.relationshipType] ?? defaultMessages
        
        // Rotate messages based on current hour for variety
        let hour = Calendar.current.component(.hour, from: Date())
        let index = hour % templates.count
        
        return templates[index]
    }
    
    /// Generates a set of messages for a person (useful for batch scheduling).
    /// Returns up to `count` unique messages by rotating through the template pool.
    static func generateMessages(for person: lowkeyPerson, count: Int) -> [String] {
        let templates = messageTemplates[person.relationshipType] ?? defaultMessages
        
        var messages: [String] = []
        for i in 0..<min(count, templates.count) {
            messages.append(templates[i])
        }
        
        // If we need more messages than templates, cycle through
        if count > templates.count {
            for i in templates.count..<count {
                messages.append(templates[i % templates.count])
            }
        }
        
        return messages
    }
}
