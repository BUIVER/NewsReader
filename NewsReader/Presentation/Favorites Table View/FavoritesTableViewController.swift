//
//  FavoritesTableViewController.swift
//  NewsReader
//
//  Created by Alexey on 20.12.15.
//  Copyright © 2015 Alexey. All rights reserved.
//

import UIKit
import CoreData

class FavoritesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var managedContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    let favoritesCellIdentifier = "FavoritesCell"
    let favoritesExitSegueIdentifier = "FavoritesExitSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.managedContext = CoreDataStack.instance.context
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: self.managedContext,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil) as? NSFetchedResultsController<NSFetchRequestResult>
        self.fetchedResultsController.delegate = self
        do {
            try self.fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error:\(error.localizedDescription)")
        }
    }
    @IBAction func addFavoriteAction(_ sender: Any) {
        let alert = UIAlertController(title: "Favorites", message: "Add new RSS Channel", preferredStyle: .alert)
        let addFavoriteAction = UIAlertAction(title: "Add", style: .default, handler: { (_: UIAlertAction!) in
            let nameTextField = alert.textFields![0]
            let linkTextField = alert.textFields![1]
            guard let favorite = NSEntityDescription.insertNewObject(forEntityName: "Favorite",
                                                                     into: self.managedContext) as? Favorite else {
                                                                        return
            }
            favorite.name = nameTextField.text
            favorite.link = linkTextField.text
            do {
                try self.managedContext.save()
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
        })
        addFavoriteAction.isEnabled = false
        alert.addTextField { (textField: UITextField!) in
            textField.placeholder = "Name"
        }
        alert.addTextField { (textField: UITextField!) in
            textField.placeholder = "Link"
            _ = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification,
                                                   object: textField,
                                                   queue: OperationQueue.main) { (_) in
                if let link = textField.text {
                    if link.hasSuffix(".xml") || link.hasSuffix(".rss") {
                        addFavoriteAction.isEnabled = true
                    }
                }
            }
        }
        alert.addAction(addFavoriteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.favoritesCellIdentifier, for: indexPath)

        guard let favorite = fetchedResultsController.object(at: indexPath) as? Favorite else {return UITableViewCell()}
        cell.textLabel?.text = favorite.name
        cell.detailTextLabel?.text = favorite.link

        return cell
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let favorite = fetchedResultsController.object(at: indexPath) as? Favorite else {return}
            self.managedContext.delete(favorite)
            do {
                try self.managedContext.save()
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
        }
    }
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            self.tableView.beginUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        if type == .insert {
            if let newIndex = newIndexPath {
            self.tableView.insertRows(at: [newIndex], with: .automatic)
            }
        } else if type == .delete {
            if let oldIndex = indexPath {
                self.tableView.deleteRows(at: [oldIndex], with: .automatic)
            }
        } else if type == .move {
            if let newIndex = newIndexPath, let oldIndex = indexPath {
                self.tableView.deleteRows(at: [oldIndex], with: .automatic)
                self.tableView.insertRows(at: [newIndex], with: .automatic)
            }
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == favoritesExitSegueIdentifier {
            if let destination = segue.destination as? NewsTableViewController {
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    guard let favorite = fetchedResultsController.object(at: indexPath) as? Favorite else {return}
                    guard let link = favorite.link else {
                        return
                    }
                    destination.rssLink = link
                }
            }
        }
    }
}
