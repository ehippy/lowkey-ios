//
//  Item.swift
//  lowkey
//
//  Created by Patrick McDavid on 7/6/25.
//

import Foundation
import SwiftData
import UIKit

@Model
class lowkeyPerson {
    var id: UUID
    var name: String
    var relationshipType: RelationshipType
    var nudgeFrequency: NudgeFrequency
    var photoData: Data?

    init(name: String,
         relationshipType: RelationshipType,
         nudgeFrequency: NudgeFrequency,
         photoData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.relationshipType = relationshipType
        self.nudgeFrequency = nudgeFrequency
        self.photoData = photoData
    }
}

// MARK: - Photo Helpers
extension lowkeyPerson {
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    func setPhoto(_ image: UIImage?) {
        if let image = image {
            // Resize image to reasonable size to save storage
            let maxSize: CGFloat = 300
            let resizedImage = image.resized(to: maxSize)
            self.photoData = resizedImage.jpegData(compressionQuality: 0.8)
        } else {
            self.photoData = nil
        }
    }
}

extension UIImage {
    func resized(to maxSize: CGFloat) -> UIImage {
        let size = self.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 {
            return self
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
