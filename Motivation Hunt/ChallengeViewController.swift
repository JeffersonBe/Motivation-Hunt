//
//  ChallengeViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 23/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import Async

class ChallengeViewController: UIViewController {

    @IBOutlet weak var challengeTextField: UITextField!
    @IBOutlet weak var challengeDatePicker: UIDatePicker!
    @IBOutlet weak var addChallengeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addChallengeView: UIView!

    var editMode: Bool = false
    var dimView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Initialize delegate
        fetchedResultsController.delegate = self
        challengeTextField.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }

        addChallengeView.hidden = true
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(ChallengeViewController.showAddChallenge))
        navigationItem.rightBarButtonItem = button
        dimView = UIView(frame: view.frame)
        dimView.backgroundColor = UIColor.blackColor()
        dimView.alpha = 0

        // Set padding on textfield: https://medium.com/@deepdeviant/how-to-set-padding-for-uitextfield-in-swift-2f830d131f40#.v25ja1v42
        let paddingView = UIView(frame: CGRectMake(0, 0, 15, challengeTextField.frame.height))
        challengeTextField.leftView = paddingView
        challengeTextField.leftViewMode = UITextFieldViewMode.Always

        view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundFeed.png")!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.insertSubview(blurEffectView, belowSubview: tableView)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.allowsMultipleSelection = false

        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            CloudKitHelper.sharedInstance.fetchChallenge { (success, record, error) in
                guard error == nil else {
                    return
                }
                Async.main() {
                    CoreDataStackManager.sharedInstance.managedObjectContext.performBlock({
                        for item in record! {
                            let _ = Challenge(challengeDescription: item["challengeDescription"] as! String, completed: item["completed"] as! Bool, endDate: item["endDate"] as! NSDate, challengeRecordID: item.recordID.recordName, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance.saveContext()
                        }
                    })
                }
            }
        }
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Challenge")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completed", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)

        return fetchedResultsController
    }()

    // MARK: Add Actions

    func showAddChallenge() {
        editMode = editMode ? false : true
        if editMode {
            showAddChallengeView()
        } else {
            HideAddChallengeView()
        }
    }

    @IBAction func addChallenge(sender: AnyObject) {
        guard challengeTextField.text != "" else {
            challengeTextField.attributedPlaceholder = NSAttributedString(string: MHClient.AppCopy.pleaseAddAChallenge, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
            return
        }

        let challengeDictionary: [String : AnyObject] = [
            "challengeDescription": self.challengeTextField.text!,
            "completed": 0,
            "endDate": self.challengeDatePicker.date
        ]

        if Reachability.connectedToNetwork() {
            CloudKitHelper.sharedInstance.saveChallenge(challengeDictionary, completionHandler: { (result, record, error) in
                if result {
                    self.addChallengeToCoreData(challengeDictionary, challengeRecordID: record.recordID.recordName)
                } else {
                    self.addChallengeToCoreData(challengeDictionary, challengeRecordID: "")
                }
            })
        }
        showAddChallenge()
    }
    func addChallengeToCoreData(challengeDictionary: [String:AnyObject], challengeRecordID: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let _ = Challenge(
                challengeDescription: challengeDictionary["challengeDescription"] as! String,
                completed: challengeDictionary["completed"] as! Bool,
                endDate: challengeDictionary["endDate"] as! NSDate,
                challengeRecordID: challengeRecordID,
                context: self.sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func showAddChallengeView() {
        challengeTextField.text = ""
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(ChallengeViewController.showAddChallenge))
        addChallengeView.hidden = false
        view.insertSubview(self.dimView, belowSubview: (self.navigationController?.navigationBar)!)
        view.insertSubview(self.addChallengeView, belowSubview: (self.navigationController?.navigationBar)!)
        challengeDatePicker.minimumDate = NSDate()
        UIView.animateWithDuration(0.3, animations: {
            self.dimView.alpha = 0.3
        })
        navigationItem.rightBarButtonItem = button
    }

    func HideAddChallengeView() {
        addChallengeView.hidden = true
        UIView.animateWithDuration(0.3, animations: {
            self.dimView.alpha = 0
            }, completion: { finished in
                self.dimView.removeFromSuperview()
        })
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(ChallengeViewController.showAddChallenge))
        navigationItem.rightBarButtonItem = button
        challengeTextField.resignFirstResponder()
    }
}

extension ChallengeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension ChallengeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let challenge = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge
        let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: indexPath)

        if challenge.completed {
            let delete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.delete) { action, index in
                self.deleteChallenge(challenge)
            }
            delete.backgroundColor = UIColor.redColor()

            let unComplete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.unComplete) { action, index in
                self.updateChallenge(challenge)
                cell.backgroundColor = UIColor.whiteColor()
                tableView.setEditing(false, animated: true)
            }
            unComplete.backgroundColor = UIColor.grayColor()
            return [delete, unComplete]
        } else {
            let complete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.complete) { action, index in
                self.updateChallenge(challenge)
                cell.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)
                tableView.setEditing(false, animated: true)
            }
            complete.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)

            let delete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.delete) { action, index in
                self.deleteChallenge(challenge)
            }
            delete.backgroundColor = UIColor.redColor()
            return [delete, complete]
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let challenge = fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge
        cell.selectionStyle = UITableViewCellSelectionStyle.None

        if challenge.completed {
            cell.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)
        }

        if !challenge.completed {
            cell.backgroundColor = UIColor.whiteColor()
        }

        if let detailTextLabel = cell.detailTextLabel {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .ShortStyle
            let dateString = formatter.stringFromDate(challenge.endDate)
            if challenge.completed {
                detailTextLabel.text = "\(MHClient.AppCopy.completedBy) \(dateString)"
            } else {
                detailTextLabel.text = "\(MHClient.AppCopy.completeBy) \(dateString)"
            }
        }

        if let textLabel = cell.textLabel {
            textLabel.text = challenge.challengeDescription
        }
    }

    func deleteChallenge(challenge: Challenge) {
        if Reachability.connectedToNetwork() && challenge.challengeRecordID != "" {
            CloudKitHelper.sharedInstance.deleteChallenge(CKRecordID(recordName: challenge.challengeRecordID), completionHandler: { (success, record, error) in
                guard success else {
                    return
                }

                Async.main {
                    self.sharedContext.deleteObject(challenge)
                    CoreDataStackManager.sharedInstance.saveContext()
                }
            })
        }
    }

    func updateChallenge(challenge: Challenge) {
        if Reachability.connectedToNetwork() && challenge.challengeRecordID != "" {
            CloudKitHelper.sharedInstance.updateCompletedStatusChallenge(CKRecordID(recordName: challenge.challengeRecordID), completionHandler: { (success, record, error) in
                guard success else {
                    return
                }

                Async.main {
                    challenge.completed = challenge.completed ? false : true
                    CoreDataStackManager.sharedInstance.saveContext()
                }
            })
        }
    }
}

extension ChallengeViewController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsController delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
        default:
            break
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type) {
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation:UITableViewRowAnimation.Fade)
            }
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Update:
            if let updateIndexPath = indexPath {
                let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: updateIndexPath)
                configureCell(cell, atIndexPath: updateIndexPath)
            }
        case .Move:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([deleteIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }

            if let insertIndexPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: insertIndexPath)
                configureCell(cell, atIndexPath: insertIndexPath)
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
