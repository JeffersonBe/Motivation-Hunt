//
//  ChallengeViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 23/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData

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
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "showAddChallenge")
        navigationItem.rightBarButtonItem = button
        dimView = UIView(frame: view.frame)
        dimView.backgroundColor = UIColor.blackColor()
        dimView.alpha = 0

        challengeDatePicker.minimumDate = NSDate()

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            challengeTextField.attributedPlaceholder = NSAttributedString(string: "Please add a challenge", attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
        let _ = Challenge(challengeDescription: self.challengeTextField.text!, completed: false, endDate: self.challengeDatePicker.date, context: self.sharedContext)
        CoreDataStackManager.sharedInstance.saveContext()
        }
        showAddChallenge()
    }

    func showAddChallengeView() {
            self.challengeTextField.text = ""
            let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "showAddChallenge")
            self.addChallengeView.hidden = false
            self.view.insertSubview(self.dimView, belowSubview: (self.navigationController?.navigationBar)!)
            self.view.insertSubview(self.addChallengeView, belowSubview: (self.navigationController?.navigationBar)!)
            UIView.animateWithDuration(0.3, animations: {
                self.dimView.alpha = 0.3
            })
            self.navigationItem.rightBarButtonItem = button
    }

    func HideAddChallengeView() {
            self.addChallengeView.hidden = true
            UIView.animateWithDuration(0.3, animations: {
                self.dimView.alpha = 0
                }, completion: { finished in
                    self.dimView.removeFromSuperview()
            })
            let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "showAddChallenge")
            self.navigationItem.rightBarButtonItem = button
            self.challengeTextField.resignFirstResponder()
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
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! challengeTableViewCell
            configureCell(cell, atIndexPath: indexPath)
            return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let challenge = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! challengeTableViewCell

        if challenge.completed {
            let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
                dispatch_async(dispatch_get_main_queue()) {
                self.sharedContext.deleteObject(challenge)
                CoreDataStackManager.sharedInstance.saveContext()
                }
            }
            delete.backgroundColor = UIColor.redColor()

            let unComplete = UITableViewRowAction(style: .Normal, title: "Uncompleted") { action, index in
                dispatch_async(dispatch_get_main_queue()) {
                challenge.completed = false
                CoreDataStackManager.sharedInstance.saveContext()
                cell.backgroundColor = UIColor.whiteColor()
                tableView.setEditing(false, animated: true)
                }
            }
            unComplete.backgroundColor = UIColor.grayColor()


            return [delete, unComplete]
        } else {
            let complete = UITableViewRowAction(style: .Normal, title: "Completed") { action, index in
                dispatch_async(dispatch_get_main_queue()) {
                challenge.completed = true
                CoreDataStackManager.sharedInstance.saveContext()
                cell.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)
                tableView.setEditing(false, animated: true)
                }
            }
            complete.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)

            let delete = UITableViewRowAction(style: .Normal, title: "Delete") { action, index in
                dispatch_async(dispatch_get_main_queue()) {
                self.sharedContext.deleteObject(challenge)
                CoreDataStackManager.sharedInstance.saveContext()
                }
            }
            delete.backgroundColor = UIColor.redColor()

            return [complete, delete]
        }
    }

    func configureCell(cell: challengeTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let challenge = fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge

        if !challenge.completed {
            cell.backgroundColor = UIColor.whiteColor()
        }

        // http://www.codingexplorer.com/swiftly-getting-human-readable-date-nsdateformatter/
        if let detailTextLabel = cell.challengeDateTextLabel {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .ShortStyle
            let dateString = formatter.stringFromDate(challenge.endDate)
            detailTextLabel.text = "Complete by: \(dateString)"
            if challenge.completed {
                cell.challengeDateTextLabel.textColor = UIColor.whiteColor()
            } else {
                detailTextLabel.textColor = UIColor.grayColor()
            }
        }

        if let textLabel = cell.challengeDescriptionTextLabel {
            textLabel.text = challenge.challengeDescription
        }
    }
}


extension ChallengeViewController: NSFetchedResultsControllerDelegate {
    // MARK: NSFetchedResultsController delegate

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
            if let indexPath = indexPath {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                    configureCell(cell as! challengeTableViewCell, atIndexPath: indexPath)
                }
            }
        case .Move:
            if let indexPath = indexPath {
                if let newIndexPath = newIndexPath {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            }
        }
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}