//
//  NRRSSParser.swift
//  News Reader
//
//  Created by Alexey on 05.10.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import CoreData

class RSSParser: NSObject, XMLParserDelegate {
    private var channel: Channel!
    private var activeItem: Item?
    private var activeElement = ""
    private var activeAttributes: [String: String]?
    private var lastPubDate: String?
    private var rssLink: String?
    
    private var isOldChannel: Bool = false
    private var isRss: Bool = false
    
    var managedContext: NSManagedObjectContext!

    var delegate: RSSParserDelegate?
    
    let node_rss = "rss"
    
    let node_channel = "channel"
    let node_item = "item"
    let node_title = "title"
    let node_link = "link"
    let node_description = "description"
    let node_category = "category"
    let node_creator = "dc:creator"
    let node_pubDate = "pubDate"
    let node_language = "language"
    let node_copyright = "copyright"
    let node_mediaContent = "media:content"
    
    let attr_url = "url"
    let attr_domain = "domain"
    let attr_version = "version"
    
    func parseWithURL(url: URL, intoManagedObjectContext managedContext: NSManagedObjectContext) {
        self.parseWithRequest(request: URLRequest(url: url), intoManagedObjectContext: managedContext)
    }
    
    func parseWithRequest(request: URLRequest, intoManagedObjectContext managedContext: NSManagedObjectContext) {
        DispatchQueue.main.async() { () -> Void in
            self.delegate?.parsingWasStarted()
        }
        
        self.managedContext = managedContext
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                self.managedContext.rollback()
                DispatchQueue.main.async() { () -> Void in
                    self.delegate?.parsingWasFinished(error)
                }
            } else {
                if let url = request.url {
                    self.rssLink = url.absoluteString
                }
                
                let parser = XMLParser(data: data!)
                parser.delegate = self
                parser.parse()
            }
        }).resume()
    }
    
    // MARK: - NSXMLParserDelegate implementation
    
    func parserDidEndDocument(_ parser: XMLParser) {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Error: \(error) " + "description \(error.localizedDescription)")
        }
        DispatchQueue.main.async { () -> Void in
            self.delegate?.parsingWasFinished(nil)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.managedContext.rollback()
        DispatchQueue.main.async() { () -> Void in
            if self.isOldChannel {
                self.delegate?.parsingWasFinished(nil)
            } else {
                self.delegate?.parsingWasFinished(parseError)
            }
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == self.node_rss {
            if let version = attributeDict[self.attr_version] {
                if version == "2.0" {
                    self.isRss = true
                }
            }
        }
        if elementName == self.node_channel {
            let channelEntity = NSEntityDescription.entity(forEntityName: "Channel", in: managedContext)
            let channelFetch = NSFetchRequest<Channel>(entityName: "Channel")
            
            do {
                let results = try self.managedContext.fetch(channelFetch)
                
                if let channel = results.first {
                    self.lastPubDate = channel.date
                    self.managedContext.delete(channel)
                }
                
                self.channel = Channel(entity: channelEntity!, insertInto: self.managedContext)
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
        }
        if elementName == self.node_item {
            let itemEntity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)
            
            self.activeItem = Item(entity: itemEntity!, insertInto: self.managedContext)
        }
        self.activeElement = ""
        self.activeAttributes = attributeDict
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.activeElement += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard self.isRss == true else {
            return
        }
        if elementName == self.node_item {
            if let item = self.activeItem {
                let items = self.channel.items!.mutableCopy() as! NSMutableOrderedSet
                
                items.add(item)
                
                self.channel.items = items.copy() as? NSOrderedSet
            }
            self.activeItem = nil
            return
        }
        if let item = self.activeItem {
            if elementName == self.node_title {
                item.title = self.activeElement
            }
            if elementName == self.node_link {
                item.link = self.activeElement
            }
            if elementName == self.node_description {
                item.itemDescription = self.activeElement
            }
            if elementName == self.node_category {
                if let attributes = self.activeAttributes {
                    if let url = attributes[self.attr_domain] {
                        let categoryEntity = NSEntityDescription.entity(forEntityName: "Category", in: self.managedContext)
                        
                        let category = Category(entity: categoryEntity!, insertInto: self.managedContext)
                        
                        category.name = self.activeElement
                        category.link = url
                        
                        let categories = item.categories!.mutableCopy() as! NSMutableOrderedSet
                        categories.add(category)
                        item.categories = categories.copy() as? NSOrderedSet
                    }
                }
            }
            if elementName == self.node_creator {
                item.creator = self.activeElement
            }
            if elementName == self.node_pubDate {
                item.date = self.activeElement
            }
            if elementName == node_mediaContent {
                if let attributes = self.activeAttributes {
                    if let url = attributes[self.attr_url] {
                        let mediaEntity = NSEntityDescription.entity(forEntityName: "Media", in: self.managedContext)
                        
                        let media = Media(entity: mediaEntity!, insertInto: self.managedContext)
                        
                        media.link = url
                        
                        let medias = item.media!.mutableCopy() as! NSMutableOrderedSet
                        medias.add(media)
                        item.media = medias.copy() as? NSOrderedSet
                    }
                }
            }
        } else {
            if elementName == self.node_title {
                self.channel.title = self.activeElement
            }
            if elementName == self.node_link {
                guard let rssLink = self.rssLink else {
                    return
                }
                self.channel.link = rssLink
            }
            if elementName == self.node_description {
                self.channel.channelDescription = self.activeElement
            }
            if elementName == self.node_language {
                self.channel.language = self.activeElement
            }
            if elementName == self.node_copyright {
                self.channel.copyright = self.activeElement
            }
            if elementName == self.node_pubDate {
                if let lastPubDate = self.lastPubDate {
                    if lastPubDate == self.activeElement {
                        self.isOldChannel = true
                        parser.abortParsing()
                    }
                }
                self.channel.date = self.activeElement
            }
        }
    }
}

protocol RSSParserDelegate {
    func parsingWasStarted()
    func parsingWasFinished(_ error: Error?)
}

