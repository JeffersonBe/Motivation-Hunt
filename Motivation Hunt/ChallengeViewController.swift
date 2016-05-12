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
import TBEmptyDataSet
import SnapKit
import GoogleAnalytics

class ChallengeViewController: UIViewController {

    var tableView: UITableView!
    var challengeTextField: UITextField!
    var challengeDatePicker: UIDatePicker!
    var addChallengeButton: UIButton!
    var addChallengeView: UIView!
    var currentChallengeToEdit: Challenge!
    var editMode: Bool = false
    var dimView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()

        // Initialize delegate
        tableView.delegate = self
        tableView.dataSource = self
        fetchedResultsController.delegate = self
        challengeTextField.delegate = self
        tableView.emptyDataSetDataSource = self
        tableView.emptyDataSetDelegate = self

        CloudKitHelper.sharedInstance.subscribeToChallengeCreation()
        CloudKitHelper.sharedInstance.fetchNotificationChanges()

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            Log.error("Error: \(error.localizedDescription)")
        }

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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "ChallengeViewController")

        let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
        tracker.send(builder as! [NSObject : AnyObject])
        addChallengeView.center.y -= view.bounds.width
        dimView.alpha = 0
    }

    override func viewDidLayoutSubviews() {
        if !editMode {
            addChallengeView.center.y -= view.bounds.width
        }
        if let rectNavigationBar = navigationController?.navigationBar.frame, let rectTabBar = tabBarController?.tabBar.frame  {
            let navigationBarSpace = rectNavigationBar.size.height + rectNavigationBar.origin.y
            let tabBarSpace = rectTabBar.size.height + rectTabBar.origin.x
            tableView.contentInset = UIEdgeInsetsMake(navigationBarSpace, 0, tabBarSpace, 0)
            addChallengeView.snp_updateConstraints(closure: { (make) in
                make.top.equalTo(navigationBarSpace)
            })
        }
    }

    func setupUI() {
        tableView = UITableView()
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.snp_makeConstraints { (make) in
            make.top.equalTo(view)
            make.width.equalTo(view)
            make.bottom.equalTo(view.snp_bottom)
        }

        addChallengeView = UIView()
        addChallengeView.backgroundColor = UIColor.whiteColor()
        view.insertSubview(addChallengeView, aboveSubview: tableView)
        addChallengeView.snp_makeConstraints { (make) in
            make.top.equalTo(view).offset(64)
            make.width.equalTo(view)
            make.height.equalTo(250)
        }

        challengeTextField = UITextField()
        challengeTextField.leftView = UIView(frame: CGRectMake(0, 0, 15, 50))
        challengeTextField.leftViewMode = UITextFieldViewMode.Always
        challengeTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        challengeTextField.backgroundColor = UIColor(red: 0.9882, green: 0.9765, blue: 0.9804, alpha: 1.0) /* #fcf9fa */
        challengeTextField.attributedPlaceholder = NSAttributedString(string: MHClient.AppCopy.pleaseAddAChallenge, attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
        addChallengeView.addSubview(challengeTextField)
        challengeTextField.snp_makeConstraints { (make) in
            make.top.equalTo(addChallengeView.topAnchor)
            make.height.equalTo(50)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        challengeDatePicker = UIDatePicker()
        addChallengeView.addSubview(challengeDatePicker)
        challengeDatePicker.snp_makeConstraints { (make) in
            make.top.equalTo(challengeTextField.snp_bottom)
            make.height.equalTo(150)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        addChallengeButton = UIButton()
        addChallengeButton.setTitle(MHClient.AppCopy.addChallenge, forState: .Normal)
        addChallengeButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        let tapToAddChallenge: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addChallenge(_:)))
        tapToAddChallenge.numberOfTapsRequired = 1
        addChallengeButton.addGestureRecognizer(tapToAddChallenge)
        addChallengeView.addSubview(addChallengeButton)
        addChallengeButton.snp_makeConstraints { (make) in
            make.top.equalTo(challengeDatePicker.snp_bottom)
            make.height.equalTo(50)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        dimView = UIView(frame: view.frame)
        dimView.backgroundColor = UIColor.blackColor()
        view.insertSubview(dimView, belowSubview: addChallengeView)

        view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundFeed.png")!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.insertSubview(blurEffectView, belowSubview: tableView)

        let blurEffectStatusBar = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurEffectViewStatusBar = UIVisualEffectView(effect: blurEffectStatusBar)
        blurEffectViewStatusBar.frame = UIApplication.sharedApplication().statusBarFrame
        view.insertSubview(blurEffectViewStatusBar, aboveSubview: tableView)

        tableView.registerClass(challengeTableViewCell.self, forCellReuseIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier)
        tableView.allowsMultipleSelection = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(ChallengeViewController.showOrHideChallengeView))

        let longTapToEditChallenge: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ChallengeViewController.editChallenge(_:)))
        longTapToEditChallenge.minimumPressDuration = 1.5
        tableView.addGestureRecognizer(longTapToEditChallenge)
        navigationController?.hidesBarsOnSwipe = true
        setNeedsStatusBarAppearanceUpdate()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Challenge")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completed", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }()

}

extension ChallengeViewController {

    func showOrHideChallengeView() {
        editMode = editMode ? false : true
        if editMode {
            showAddChallengeView()
        } else {
            HideAddChallengeView()
        }
    }

    func addChallenge(_: UIGestureRecognizer) {

        let challengeDictionary: [String : AnyObject] = [
            "challengeDescription": challengeTextField.text!,
            "completed": 0,
            "endDate": challengeDatePicker.date
        ]

        guard challengeTextField.text != "" else {
            challengeTextField.attributedPlaceholder = NSAttributedString(string: MHClient.AppCopy.pleaseAddAChallenge, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
            return
        }

        guard currentChallengeToEdit == nil else {
            Async.main {
                self.currentChallengeToEdit.challengeDescription = self.challengeTextField.text!
                self.currentChallengeToEdit.endDate = self.challengeDatePicker.date
                CoreDataStackManager.sharedInstance.saveContext()
            }

            CloudKitHelper.sharedInstance.updateChallenge(challengeDictionary["challengeDescription"] as! String, endDate: challengeDictionary["endDate"] as! NSDate, challengeRecordID: CKRecordID(recordName: currentChallengeToEdit.challengeRecordID), completionHandler: { (success, record, error) in

                guard error == nil else {
                    return
                }
            })
            showOrHideChallengeView()
            return
        }

        CloudKitHelper.sharedInstance.saveChallenge(challengeDictionary, completionHandler: { (result, record, error) in
            if result {
                self.addChallengeToCoreData(challengeDictionary, challengeRecordID: record.recordID.recordName)
            }
        })
        showOrHideChallengeView()
    }

    func editChallenge(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            let tapPoint: CGPoint = gestureRecognizer.locationInView(tableView)
            let indexPath = tableView.indexPathForRowAtPoint(tapPoint)
            currentChallengeToEdit = fetchedResultsController.objectAtIndexPath(indexPath!) as! Challenge
            showOrHideChallengeView()
        }
    }

    func addChallengeToCoreData(challengeDictionary: [String:AnyObject], challengeRecordID: String) {
        Async.main {
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
        if currentChallengeToEdit != nil {
            challengeTextField.text = currentChallengeToEdit!.challengeDescription
            challengeDatePicker.date = currentChallengeToEdit!.endDate
            addChallengeButton.setTitle("Modify challenge", forState: .Normal)
        }

        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            self.addChallengeView.center.y += self.view.bounds.width
            self.dimView.alpha = 0.3
            }, completion: { finished in
                self.navigationController?.hidesBarsOnSwipe = false
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                    target: self,
                    action: #selector(ChallengeViewController.showOrHideChallengeView)
                )
        })
    }

    func HideAddChallengeView() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
            self.addChallengeView.center.y -= self.view.bounds.width
            self.dimView.alpha = 0
            }, completion: { finished in
                self.navigationController?.hidesBarsOnSwipe = true
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.Add,
                    target: self,
                    action: #selector(ChallengeViewController.showOrHideChallengeView)
                )
                self.challengeTextField.resignFirstResponder()
        })
    }
}

extension ChallengeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension ChallengeViewController: TBEmptyDataSetDataSource, TBEmptyDataSetDelegate {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString? {
        // return the description for EmptyDataSet
        let title = "You don't have any challenge"
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(24.0), NSForegroundColorAttributeName: UIColor.grayColor()]
        return NSAttributedString(string: title, attributes: attributes)
    }

    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage? {
        let image = UIImage(named: "iconChallenge")
        return image
    }

    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString? {
        let title = "Challenge yourself!"
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18.00), NSForegroundColorAttributeName: UIColor.grayColor()]
        return NSAttributedString(string: title, attributes: attributes)
    }

    func emptyDataSetDidTapView(scrollView: UIScrollView!) {
        showOrHideChallengeView()
    }

    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        guard fetchedResultsController.fetchedObjects?.count == 0 else {
            return false
        }

        return true
    }
}

extension ChallengeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections?[section]
        if fetchedResultsController.sections?[section].numberOfObjects < 10 {
            navigationController?.hidesBarsOnSwipe = false
            setNeedsStatusBarAppearanceUpdate()
        }
        return sectionInfo!.numberOfObjects
    }

    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: indexPath) as! challengeTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(cell: challengeTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let challenge = fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge
        cell.selectionStyle = UITableViewCellSelectionStyle.None

        if challenge.completed {
            cell.backgroundColor = UIColor(red:0.52, green:0.86, blue:0.09, alpha:1.0)
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }

        if let challengeDateTextLabel = cell.challengeDateTextLabel {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.LongStyle
            formatter.timeStyle = .ShortStyle
            let dateString = formatter.stringFromDate(challenge.endDate)
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

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let challenge = fetchedResultsController.objectAtIndexPath(indexPath) as! Challenge
        let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: indexPath)

        if challenge.completed {
            let delete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.delete) { action, index in
                self.deleteChallenge(challenge)
            }
            delete.backgroundColor = UIColor.redColor()

            let unComplete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.unComplete) { action, index in
                self.updateCompleteStatusChallenge(challenge)
                cell.backgroundColor = UIColor.whiteColor()
                tableView.setEditing(false, animated: true)
            }
            unComplete.backgroundColor = UIColor.grayColor()
            return [delete, unComplete]
        } else {
            let complete = UITableViewRowAction(style: .Normal, title: MHClient.AppCopy.complete) { action, index in
                self.updateCompleteStatusChallenge(challenge)
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

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }

    func deleteChallenge(challenge: Challenge) {
        CloudKitHelper.sharedInstance.deleteChallenge(CKRecordID(recordName: challenge.challengeRecordID), completionHandler: { (success, record, error) in
            guard success else {
                return
            }
        })
        Async.main {
            self.sharedContext.deleteObject(challenge)
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func updateCompleteStatusChallenge(challenge: Challenge) {
        CloudKitHelper.sharedInstance.updateCompletedStatusChallenge(CKRecordID(recordName: challenge.challengeRecordID), completionHandler: { (success, record, error) in
            guard success else {
                return
            }
        })
        Async.main {
            challenge.completed = challenge.completed ? false : true
            CoreDataStackManager.sharedInstance.saveContext()
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
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Update:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move:
            tableView.moveSection(sectionIndex, toSection: sectionIndex)
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type) {
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        case .Update:
            if let updateIndexPath = indexPath {
                tableView.reloadRowsAtIndexPaths([updateIndexPath], withRowAnimation: .Fade)
            }
        case .Move:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([deleteIndexPath], withRowAnimation: .Fade)
            }

            if let insertIndexPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                let cell = tableView.dequeueReusableCellWithIdentifier(MHClient.CellIdentifier.cellWithReuseIdentifier, forIndexPath: insertIndexPath)
                configureCell(cell as! challengeTableViewCell, atIndexPath: insertIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
