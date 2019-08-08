//
//  UIImageView+setImageFromURL.swift
//  News Reader
//
//  Created by Alexey on 12.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit

extension UIImageView {
    func setImageFromURL(url: URL) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async { () -> Void in
                self.image = UIImage(data: data)
            }
        }).resume()
    }
    func setImageAnimated(image: UIImage?, interval: TimeInterval, animationOption: UIView.AnimationOptions) {
        UIView.transition(with: self, duration: interval, options: animationOption, animations: { () -> Void in
            self.image = image
            }, completion: nil)
    }
}
