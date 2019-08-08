//
//  WebViewController.swift
//  News Reader
//
//  Created by Alexey on 24.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

// Storyboard -> Xib - Need to move activityIndicator

import UIKit
import WebKit

//
//    

class WebViewController: UIViewController {

    @IBOutlet var browserView: WKWebView!
    @IBOutlet weak var navigation: UINavigationBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var delegate: WebViewDelegate?
    @IBAction func takeSnapshot(_ sender: Any) {
        browserView.takeSnapshot(with: nil, completionHandler: ({ image, error in
                if let img = image {
                self.delegate?.snapshotTaken(img)
                }
            }))
    }
    
    @IBAction func copyAction(_ sender: Any) {
        guard let url = browserView.url else {
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add to clipboard", style: .default) { (UIAlertAction) -> Void in
            UIPasteboard.general.string = url.absoluteString
        })
        alert.addAction(UIAlertAction(title: "Open in Safari", style: .default) { (UIAlertAction) -> Void in
            UIApplication.shared.open(url, options: .init(), completionHandler: nil)
            //            UIApplication.shared.openURL(url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.delegate?.copyActionCreated(alert)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol WebViewDelegate {
    func snapshotTaken(_ image: UIImage)
    func copyActionCreated(_ alert: UIAlertController)
}
