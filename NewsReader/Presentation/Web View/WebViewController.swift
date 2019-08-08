//
//  WebViewController.swift
//  NewsReader
//
//  Created by Ivan Ermak on 8/8/19.
//  Copyright © 2019 Ivan Ermak. All rights reserved.
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

class WebViewController: UIViewController {
    var img: UIImage?
    var item: Item?
    let drawingSB = UIStoryboard(name: "DrawingViewController",
                                 bundle: nil).instantiateInitialViewController() as? DrawingViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = item?.title
        guard let url = item?.url else {return}
        let request = URLRequest(url: url)
        browserView.load(request)
        browserView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        // Do any additional setup after loading the view.
    }
    @IBOutlet var browserView: WKWebView!
    @IBOutlet weak var navigation: UINavigationItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func takeSnapshot(_ sender: Any) {
        browserView.takeSnapshot(with: nil, completionHandler: ({ image, _ in
            self.drawingSB?.sourceImage = image
            self.present(self.drawingSB!, animated: true, completion: nil)
        }))
    }
    @IBAction func copyAction(_ sender: Any) {
        guard let url = browserView.url else {
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add to clipboard", style: .default) { (_) -> Void in
            UIPasteboard.general.string = url.absoluteString
        })
        alert.addAction(UIAlertAction(title: "Open in Safari", style: .default) { (_) -> Void in
            UIApplication.shared.open(url, options: .init(), completionHandler: nil)
            //            UIApplication.shared.openURL(url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if !self.browserView.isLoading {
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
}
