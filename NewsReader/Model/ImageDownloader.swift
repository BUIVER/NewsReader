//
//  ImageDownloader.swift
//  News Reader
//
//  Created by Alexey on 14.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit

class ImageDownloader {
    func downloadImageWithURL(url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            if let data = data {
                let image = UIImage(data: data)
                completion(image, nil)
            } else {
                completion(nil, error)
            }
        }).resume()
    }
}
