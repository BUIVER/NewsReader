//
//  WebViewController.swift
//  News Reader
//
//  Created by Alexey on 24.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import WebKit
class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {//stb -> xib
    @IBOutlet var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityBackground: UIVisualEffectView!
    
    var url: URL?
    var wkWebView: WKWebView!
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        guard let url = self.url else {
            return
        }
        
        let request = URLRequest(url: url)
        self.webView.allowsLinkPreview = true
        debugPrint(self.webView.isLoading)
        DispatchQueue.main.async {
            self.webView.load(request)
            
            debugPrint(self.webView.isLoading)
            
        }
        debugPrint(self.webView.isLoading)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("Finished")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    // MARK: - Button actions
    
    @IBAction func copyAction(_ sender: AnyObject) {
        guard let url = self.url else {
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add to clipboard", style: .default) { (UIAlertAction) -> Void in
            UIPasteboard.general.string = url.absoluteString
        })
        alert.addAction(UIAlertAction(title: "Open in Safari", style: .default) { (UIAlertAction) -> Void in
            UIApplication.shared.openURL(url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.activityIndicator.startAnimating()
        self.activityBackground.isHidden = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.activityIndicator.stopAnimating()
        self.activityBackground.isHidden = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
