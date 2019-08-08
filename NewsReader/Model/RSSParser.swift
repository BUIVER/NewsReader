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
    weak var delegate: RSSParserDelegate?
    let nodeRss = "rss"
    let nodeChannel = "channel"
    let nodeItem = "item"
    let nodeTitle = "title"
    let nodeLink = "link"
    let nodeDescription = "description"
    let nodeCategory = "category"
    let nodeCreator = "dc:creator"
    let nodePubDate = "pubDate"
    let nodeLanguage = "language"
    let nodeCopyright = "copyright"
    let nodeMediaContent = "media:content"
    let attrUrl = "url"
    let attrDomain = "domain"
    let attrVersion = "version"
    func parseWithURL(url: URL, intoManagedObjectContext managedContext: NSManagedObjectContext) {
        self.parseWithRequest(request: URLRequest(url: url),
                              intoManagedObjectContext: managedContext)
    }
    func parseWithRequest(request: URLRequest, intoManagedObjectContext managedContext: NSManagedObjectContext) {
        DispatchQueue.main.async { () -> Void in
            self.delegate?.parsingWasStarted()
        }
        self.managedContext = managedContext
        URLSession.shared.dataTask(with: request,
                                   completionHandler: { (data, _, error) -> Void in
            if let error = error {
                self.managedContext.rollback()
                DispatchQueue.main.async { () -> Void in
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
        DispatchQueue.main.async { () -> Void in
            if self.isOldChannel {
                self.delegate?.parsingWasFinished(nil)
            } else {
                self.delegate?.parsingWasFinished(parseError)
            }
        }
    }
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        if elementName == self.nodeRss {
            if let version = attributeDict[self.attrVersion] {
                if version == "2.0" {
                    self.isRss = true
                }
            }
        }
        if elementName == self.nodeChannel {
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
        if elementName == self.nodeItem {
            let itemEntity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)
            self.activeItem = Item(entity: itemEntity!, insertInto: self.managedContext)
        }
        self.activeElement = ""
        self.activeAttributes = attributeDict
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.activeElement += string
    }
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        guard self.isRss == true else {
            return
        }
        if elementName == self.nodeItem {
            if let item = self.activeItem {
                guard let items = self.channel.items?.mutableCopy() as? NSMutableOrderedSet else {
                    return
                }
                items.add(item)
                self.channel.items = items.copy() as? NSOrderedSet
            }
            self.activeItem = nil
            return
        }
        if let item = self.activeItem {
            itemActive(item, elementName)
        } else {
            itemNonActive(elementName, parser)
        }
    }
    func itemActive(_ item: Item, _ elementName: String) {
        if elementName == self.nodeTitle {
            item.title = self.activeElement
        }
        if elementName == self.nodeLink {
            item.link = self.activeElement
        }
        if elementName == self.nodeDescription {
            item.itemDescription = self.activeElement
        }
        if elementName == self.nodeCategory {
            if let attributes = self.activeAttributes {
                if let url = attributes[self.attrDomain] {
                    let categoryEntity = NSEntityDescription.entity(forEntityName: "Category",
                                                                    in: self.managedContext)
                    let category = Category(entity: categoryEntity!,
                                            insertInto: self.managedContext)
                    category.name = self.activeElement
                    category.link = url
                    guard let categories = item.categories?.mutableCopy() as? NSMutableOrderedSet else {return}
                    categories.add(category)
                    item.categories = categories.copy() as? NSOrderedSet
                }
            }
        }
        if elementName == self.nodeCreator {
            item.creator = self.activeElement
        }
        if elementName == self.nodePubDate {
            item.date = self.activeElement
        }
        if elementName == nodeMediaContent {
            if let attributes = self.activeAttributes {
                if let url = attributes[self.attrUrl] {
                    let mediaEntity = NSEntityDescription.entity(forEntityName: "Media", in: self.managedContext)
                    let media = Media(entity: mediaEntity!, insertInto: self.managedContext)
                    media.link = url
                    guard let medias = item.media?.mutableCopy() as? NSMutableOrderedSet else {return}
                    medias.add(media)
                    item.media = medias.copy() as? NSOrderedSet
                }
            }
        }
    }
    func itemNonActive(_ elementName: String, _ parser: XMLParser) {
        if elementName == self.nodeTitle {
            self.channel.title = self.activeElement
        }
        if elementName == self.nodeLink {
            guard let rssLink = self.rssLink else {
                return
            }
            self.channel.link = rssLink
        }
        if elementName == self.nodeDescription {
            self.channel.channelDescription = self.activeElement
        }
        if elementName == self.nodeLanguage {
            self.channel.language = self.activeElement
        }
        if elementName == self.nodeCopyright {
            self.channel.copyright = self.activeElement
        }
        if elementName == self.nodePubDate {
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

protocol RSSParserDelegate: class {
    func parsingWasStarted()
    func parsingWasFinished(_ error: Error?)
}
