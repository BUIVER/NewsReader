//
//  NewsTableViewController.swift
//  News Reader
//
//  Created by Alexey on 01.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import CoreData

class NewsTableViewController: UITableViewController, RSSParserDelegate {
    var managedContext: NSManagedObjectContext!
    var channel: Channel?
    var imageDownloadsInProgress = [IndexPath: ImageDownloader]()
    
    lazy var rssLink: String = {
        var link: String = "http://www.nytimes.com/services/xml/rss/nyt/World.xml"
        if let channel = self.channel {
            if let channelLink = channel.link {
                link = channelLink
            }
        }
        return link
    }()
    
    @IBOutlet var table: UITableView!
    let detailSegueIdentifier = "DetailedSegue"
    let favoritesSegueIdentifier = "FavoritesSegue"
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.table.dataSource = self
        self.table.delegate = self
        self.table.register(UINib(nibName: "NewsCell", bundle: nil), forCellReuseIdentifier: "NewsCell")
        self.table.register(UINib(nibName: "ImageNewsCell", bundle: nil), forCellReuseIdentifier: "ImageNewsCell")
        self.managedContext = CoreDataStack.instance.context
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 160.0
        
        if self.fetchData() {
            if let channel = self.channel {
                self.title = channel.title
            }
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Unwind segues
    
    @IBAction func favoritesExitSegue(_ segue:UIStoryboardSegue) {
        self.beginParsing()
    }
    
    // MARK: - Button actions
    
    @IBAction func changeRSSSource(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "RSS Source", message: "Change RSS source link", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0]
            if let newLink = textField.text {
                self.rssLink = newLink
            }
            self.beginParsing()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func refreshButtonAction(_ sender: UIBarButtonItem) {
        self.beginParsing()
    }
    
    // MARK: - Helpers
    
    func sendMessageWithError(error: Error, withTitle title: String) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default,handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func beginParsing() {
        let privateManagedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateManagedContext.parent = self.managedContext
        
        privateManagedContext.perform {
            DispatchQueue.main.async { () -> Void in
                if let url = URL(string: self.rssLink) {
                    let parser = RSSParser()
                    parser.delegate = self
                    parser.parseWithURL(url: url, intoManagedObjectContext: privateManagedContext)
                }
            }
        }
    }
    
    func fetchData() -> Bool {
        let channelFetch = NSFetchRequest<Channel>(entityName: "Channel")
        do {
            let results = try self.managedContext.fetch(channelFetch)
            
            if results.count > 0 {
                self.channel = results.first
                return true
            } else {
                return false
            }
        } catch let error {
            print("Error: \(error) " + "description \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - NRRSSParserDelegate
    
    func parsingWasStarted() {
        if let leftBarButtomItem = self.navigationItem.leftBarButtonItem {
            leftBarButtomItem.isEnabled = false
        }
        self.title = "Loading..."
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func parsingWasFinished(_ error: Error?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if let error = error {
            self.sendMessageWithError(error: error, withTitle: "Parsing error")
            
            if self.fetchData() {
                if let channel = self.channel {
                    self.title = channel.title
                }
                self.tableView.reloadData()
            } else {
                self.title = "News Reader"
            }
            
            if let leftBarButtomItem = self.navigationItem.leftBarButtonItem {
                leftBarButtomItem.isEnabled = true
            }
            return
        } else {
            if self.fetchData() {
                if let channel = self.channel {
                    self.title = channel.title
                }
                self.tableView.reloadData()
            }
            
            if let leftBarButtomItem = self.navigationItem.leftBarButtonItem {
                leftBarButtomItem.isEnabled = true
            }
        }
    }

    // MARK: - Table view data source

    func loadImagesForOnscreenRows() {
        guard let channel = self.channel else {
            return
        }
        guard let visiblePaths = self.tableView.indexPathsForVisibleRows else {
            return
        }
        
        for indexPath in visiblePaths {
            let item = channel.items![indexPath.row] as! Item
            if let _ = item.thumbnailImage {
                continue
            }
            if let _ = item.thumbnail {
                let cell = tableView.cellForRow(at: indexPath) as! ImageNewsCell
                self.startThumbnailDownload(item: item, indexPath: indexPath, cell: cell)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueIdentifier {
            if let destination = segue.destination as? NewsDetailTableViewController {
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    if let channel = self.channel {
                        destination.item = channel.items![indexPath.row] as? Item
                    }
                }
            }
        }
        if segue.identifier == favoritesSegueIdentifier {
            if let destination = segue.destination as? FavoritesTableViewController {
                destination.managedContext = self.managedContext
            }
        }
    }
}

//Table functions extension
extension NewsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
         return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let channel = self.channel else {
            return 0
        }
        return channel.items!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let channel = self.channel else {
            return UITableViewCell()
        }
        let item = channel.items![indexPath.row] as! Item
        let check = item.thumbnail == nil
        return check ? self.newsCellAtIndexPath(indexPath: indexPath, channel: channel, cellType: NewsCell.self) : self.imageNewsCellAtIndexPath(indexPath: indexPath, channel: channel, cellType: ImageNewsCell.self)
    }
    
    func newsCellAtIndexPath(indexPath: IndexPath, channel: Channel, cellType: NewsCell.Type) -> UITableViewCell {
        return tableView.dequeueCell(for: cellType, configure: ({cell in
            let item = channel.items![indexPath.row] as! Item
            cell.fillNewsCell(item)
        }))
    }
    func imageNewsCellAtIndexPath(indexPath: IndexPath, channel: Channel, cellType: ImageNewsCell.Type) -> UITableViewCell {
        return tableView.dequeueCell(for: cellType, configure: ({cell in
            let item = channel.items![indexPath.row] as! Item
            cell.fillNewsCell(item)
            if(item.thumbnail != nil) {
                
                cell.tag = indexPath.row
                if let thumbnailImage = item.thumbnailImage {
                    cell.thumbnailImageView.image = thumbnailImage
                }
                else {
                    if self.tableView.isDragging == false && self.tableView.isDecelerating == false {
                        self.startThumbnailDownload(item: item, indexPath: indexPath, cell: cell)
                    }
                    cell.thumbnailImageView.setImageAnimated(image: UIImage(named: "ThumbnailPlaceholder.png"), interval: 0.1, animationOption: .transitionCrossDissolve)
                }
            }
            
        }))
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "DetailedSegue", sender: nil)
    }
    // MARK: - Image downloading helpers
    
    func startThumbnailDownload(item: Item, indexPath: IndexPath, cell: ImageNewsCell) {
        if let _ = self.imageDownloadsInProgress[indexPath] {
            return
        }
        guard let thumbnailURL = item.thumbnail else {
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let imageDownloader = ImageDownloader()
        imageDownloader.downloadImageWithURL(url: thumbnailURL, completion: { [unowned self] (image, error) -> Void in
            if let error = error {
                self.sendMessageWithError(error: error, withTitle: "Image downloading Error")
                self.imageDownloadsInProgress.removeValue(forKey: indexPath)
                if self.imageDownloadsInProgress.count == 0 {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                return
            }
            
            DispatchQueue.main.async {
                if indexPath.row == cell.tag {
                    cell.thumbnailImageView.setImageAnimated(image: image, interval: 0.2, animationOption: .transitionFlipFromTop)
                }
            }
            
            item.thumbnailImage = image
            
            do {
                try self.managedContext.save()
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
            
            self.imageDownloadsInProgress.removeValue(forKey: indexPath)
            if self.imageDownloadsInProgress.count == 0 {
                DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        })
        self.imageDownloadsInProgress[indexPath] = imageDownloader
    }
}

protocol CellIdentifiable: UITableViewCell {
    static var identifier: String { get }
}

extension UITableViewCell: CellIdentifiable {
    static var identifier: String {
        return String(describing: self)
    }
}

extension UITableView {
    func dequeueCell<Type: CellIdentifiable>(for type: Type.Type, configure: ((Type) -> Void)? = nil) -> UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: Type.identifier) as? Type else {
            return UITableViewCell()
        }
        
        configure?(cell)
        return cell
    }
}
