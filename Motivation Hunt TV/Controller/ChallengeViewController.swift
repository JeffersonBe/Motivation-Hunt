//
//  ChallengeViewController.swift
//  Motivation Hunt TV
//
//  Created by Jefferson Bonnaire on 12/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit

class ChallengeViewController: UIViewController {
    
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()
        
        // Initialize delegate
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(challengeTableViewCell.self,
                           forCellReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            Log.error("Error: \(error.localizedDescription)")
        }
    }
    
    // Initialize CoreData and NSFetchedResultsController
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.shared.persistentContainer.viewContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Challenge> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Challenge")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "completed", ascending: true),
            NSSortDescriptor(key: "endDate", ascending: true)
        ]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController as! NSFetchedResultsController<Challenge>
    }()
}

extension ChallengeViewController {
    func setupUI() {
        tableView = UITableView()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
}

extension ChallengeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        print(sectionInfo.numberOfObjects)
        
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: indexPath) as! challengeTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: challengeTableViewCell, atIndexPath indexPath: IndexPath) {
        let challenge = fetchedResultsController.object(at: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        if challenge.completed {
            cell.backgroundColor = #colorLiteral(red: 0.3003999591, green: 0.851647675, blue: 0.4030759931, alpha: 1)
        } else if challenge.endDate < Date() {
            cell.backgroundColor = #colorLiteral(red: 0.994312346, green: 0.2319896519, blue: 0.1840049326, alpha: 1)
        }
        
        if let challengeDateTextLabel = cell.challengeDateTextLabel {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.long
            formatter.timeStyle = .short
            let dateString = formatter.string(from: challenge.endDate)
            if challenge.completed {
                challengeDateTextLabel.text = "\(MHClient.AppCopy.completedBy) \(dateString)"
            } else {
                challengeDateTextLabel.text = "\(MHClient.AppCopy.completeBy) \(dateString)"
            }
        }
        
        if let challengeDescriptionTextLabel = cell.challengeDescriptionTextLabel {
            challengeDescriptionTextLabel.text = challenge.challengeDescription
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
}

extension ChallengeViewController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsController delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            tableView.moveSection(sectionIndex, toSection: sectionIndex)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let updateIndexPath = indexPath {
                tableView.reloadRows(at: [updateIndexPath], with: .fade)
            }
        case .move:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRows(at: [deleteIndexPath], with: .fade)
            }
            
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRows(at: [insertIndexPath], with: UITableViewRowAnimation.fade)
                let cell = tableView.dequeueReusableCell(withIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: insertIndexPath)
                configureCell(cell as! challengeTableViewCell, atIndexPath: insertIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
