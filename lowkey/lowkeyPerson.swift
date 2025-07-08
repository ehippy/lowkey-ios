//
//  Item.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/6/25.
//

import Foundation
import SwiftData

@Model
class lowkeyPerson {
    var name: String
    var relationshipType: RelationshipType
    var nudgeFrequency: NudgeFrequency

    init(name: String,
         relationshipType: RelationshipType,
         nudgeFrequency: NudgeFrequency) {
        self.name = name
        self.relationshipType = relationshipType
        self.nudgeFrequency = nudgeFrequency
    }
}
