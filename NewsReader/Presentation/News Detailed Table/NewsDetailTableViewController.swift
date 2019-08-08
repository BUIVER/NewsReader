//
//  NewsDetailViewController.swift
//  News Reader
//
//  Created by Alexey on 08.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import WebKit

class NewsDetailTableViewController: UITableViewController, WKUIDelegate {
    var item: Item?
    
    let detailNewsCellIdentifier = "DetailNewsCell"
    let detailImageNewsCellIdentifier = "DetailImageNewsCell"
    let categoriesNewsCellIdentifier = "CategoriesNewsCell"
    let mediaNewsCellIdentifier = "MediaNewsCell"
    var webView = Bundle.main.loadNibNamed("WebView", owner: self, options: nil)?.first as? WebViewController
    var snapshot: UIImage?
    var currentUrl : URL?
    let itemLinkSegueIdentifier = "WebViewSegue"
    let categoryLinkSegueIdentifier = "CategoryLinkSegue"
    let mediaLinkSegueIdentifier = "MediaLinkSegue"
    let drawingSegueIdentifier = "DrawingSegue"
    @IBOutlet weak var snapshotButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView?.titleString = item?.title
        self.webView?.browserView.uiDelegate = self
        self.currentUrl = self.item?.url
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 160.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.currentUrl = self.item?.url
        if let item = self.item {
            self.title = item.title
        }
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Unwind segues
    @IBAction func webViewCall (_ sender: Any) {
        webView?.navigation.title = self.title
        guard let url = currentUrl else {return}
        let request = URLRequest(url: url)
        self.webView?.browserView.load(request)
        self.show(webView!, sender: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let _ = self.item else {
            return 1
        }
        return 3
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let item = self.item {
            if section == 1 && item.categories!.count > 0 {
                return "Categories"
            } else if section == 2 && item.media!.count > 0 {
                return "Media"
            }
        }
        return nil
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let item = self.item {
            if section == 0 {
                return 1
            } else if section == 1 {
                return item.categories!.count
            } else if section == 2 {
                return item.media!.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = self.item else {
            return UITableViewCell()
        }
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.categoriesNewsCellIdentifier, for: indexPath) as UITableViewCell
            
            let category = item.categories![indexPath.row] as! Category
            cell.textLabel?.text = category.name
            
            return cell
        }
        
        if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.mediaNewsCellIdentifier, for: indexPath) as UITableViewCell
            
            let media = item.media![indexPath.row] as! Media
            cell.textLabel?.text = media.link
            
            return cell
        }
        
        guard let imageURL = item.thumbnail else {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.detailNewsCellIdentifier) as! DetailNewsCell
            
            cell.titleLabel.text = item.title
            cell.dateLabel.text = item.date?.formatDate()
            cell.authorLabel.text = item.creator
            cell.descriptionLabel.text = item.minifiedDescription
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.detailImageNewsCellIdentifier) as! DetailImageNewsCell
        
        cell.titleLabel.text = item.title
        cell.dateLabel.text = item.date?.formatDate()
        cell.authorLabel.text = item.creator
        cell.descriptionLabel.text = item.minifiedDescription
        if let image = item.thumbnailImage {
            cell.thumbnailImageView.image = image
        } else {
            cell.thumbnailImageView.setImageFromURL(url: imageURL)
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let cell = item?.categories![indexPath.row] as! Category
            self.currentUrl = cell.url
            webViewCall(self)
            break
        case 2:
            let cell = item?.media![indexPath.row] as! Media
            self.currentUrl = cell.url
            webViewCall(self)
            break
        default:
            break
        }
    }
    // MARK: - Navigation
}
/* extension NewsDetailTableViewController {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.webView?.activityIndicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            self.webView?.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
*/
