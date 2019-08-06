//
//  Item.swift
//  News Reader
//
//  Created by Alexey on 02.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import CoreData

class Item: NSManagedObject {
    var minifiedDescription: String? {
        guard let description = self.itemDescription else {
            return nil
        }
        
        var resultString = description
        var tags = [String]()
        
        let regex = try! NSRegularExpression(pattern: "<(.*?)>", options: .caseInsensitive)
        regex.enumerateMatches(in: description, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, description.count)) { (result, _, _) in
            if let result = result {
                let string = (description as NSString).substring(with: result.range) as String
                tags.append(string)

            }
        }
        
        for tag in tags {
            resultString = resultString.replacingOccurrences(of: tag, with: "")
        }
        
        return resultString
    }
    
    var thumbnailImage: UIImage? {
        set {
            if let image = newValue {
                if let data = image.pngData() {
                    self.thumbnailData = data as NSData
                }
            }
        }
        get {
            guard let data = self.thumbnailData else {
                return nil
            }
            guard let image = UIImage(data: data as Data) else {
                return nil
            }
            return image
        }
    }
    
    var thumbnail: URL? {
        var url: URL?
        
        guard let media = self.media else {
            return url
        }
        
        for item in media.array {
            let mediaItem = item as! Media
            guard let mediaLink = mediaItem.link else {
                continue
            }
            
            var stringURL = mediaLink
            
            let regex = try! NSRegularExpression(pattern: "(https?)\\S*(png|jpg|jpeg|gif)", options: .caseInsensitive)
            
            if let result = regex.firstMatch(in: stringURL, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, stringURL.count)) {
                stringURL = (stringURL as NSString).substring(with: result.range) as String
                url = URL(string: stringURL)
                break
            }
        }
        
        return url
    }
    
    var url: URL? {
        guard let link  = self.link else {
            return nil
        }
        if let url = URL(string: link) {
            return url
        }
        return nil
    }
}
