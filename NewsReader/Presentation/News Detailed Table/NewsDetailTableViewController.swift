//
//  NewsDetailViewController.swift
//  News Reader
//
//  Created by Alexey on 08.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

// Lifecycle
// Presentation
// NavtigationController
// Connection between View and ViewController


import UIKit
import WebKit

class NewsDetailTableViewController: UITableViewController {
    var item: Item?
    let detailNewsCellIdentifier = "DetailNewsCell"
    let detailImageNewsCellIdentifier = "DetailImageNewsCell"
    let categoriesNewsCellIdentifier = "CategoriesNewsCell"
    let mediaNewsCellIdentifier = "MediaNewsCell"
    var currentUrl: URL?
    override func viewDidLoad() {
        super.viewDidLoad()
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
    @IBAction func webViewCall (_ sender: Any) {
        let webView = WebViewController(nibName: "WebViewController", bundle: nil)
        webView.item = item
        self.show(webView, sender: nil)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard self.item != nil else {
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
        let detailId = self.detailImageNewsCellIdentifier
        guard let item = self.item else {
            return UITableViewCell()
        }
        if indexPath.section == 1 {
            let categoryId = self.categoriesNewsCellIdentifier
            let cell = tableView.dequeueReusableCell(withIdentifier: categoryId,
                                                     for: indexPath) as UITableViewCell
            guard let category = item.categories![indexPath.row] as? Category else {
                return UITableViewCell()
            }
            cell.textLabel?.text = category.name
            return cell
        }
        if indexPath.section == 2 {
            let mediaId = self.mediaNewsCellIdentifier
            let cell = tableView.dequeueReusableCell(withIdentifier: mediaId,
                                                     for: indexPath) as UITableViewCell
            guard let media = item.media![indexPath.row] as? Media else {
                return UITableViewCell()
            }
            cell.textLabel?.text = media.link
            return cell
        }
        guard let imageURL = item.thumbnail else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: detailId) as? DetailNewsCell else {
                return UITableViewCell()
            }
            cell.titleLabel.text = item.title
            cell.dateLabel.text = item.date?.formatDate()
            cell.authorLabel.text = item.creator
            cell.descriptionLabel.text = item.minifiedDescription
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: detailId) as? DetailImageNewsCell else {
            return UITableViewCell()
        }
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
            guard let cell = item?.categories![indexPath.row] as? Category else {return}
            self.currentUrl = cell.url
            webViewCall(self)
        case 2:
            guard let cell = item?.media![indexPath.row] as? Media else {return}
            self.currentUrl = cell.url
            webViewCall(self)
        default:
            break
        }
    }
    // MARK: - Navigation
}
