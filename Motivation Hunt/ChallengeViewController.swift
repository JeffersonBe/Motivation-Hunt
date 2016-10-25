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
import DZNEmptyDataSet
import SnapKit
import GoogleAnalytics

class ChallengeViewController: UIViewController {

    var tableView: UITableView!
    var challengeTextField: UITextField!
    var challengeDatePicker: UIDatePicker!
    var addChallengeButton: UIButton!
    var addChallengeView: UIView!
    var currentChallengeToEdit: Challenge?
    var editMode: Bool = false
    var dimView: UIView!
    let layer = CAGradientLayer()

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
        challengeTextField.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            Log.error("Error: \(error.localizedDescription)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "ChallengeViewController")

        let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
        tracker?.send(builder as! [AnyHashable: Any])
        addChallengeView.center.y -= view.bounds.width
        dimView.alpha = 0
    }

    override func viewDidLayoutSubviews() {
        layer.frame = view.frame
        if !editMode {
            addChallengeView.center.y -= view.bounds.width
        }
        if let rectNavigationBar = navigationController?.navigationBar.frame, let rectTabBar = tabBarController?.tabBar.frame  {
            let navigationBarSpace = rectNavigationBar.size.height + rectNavigationBar.origin.y
            let tabBarSpace = rectTabBar.size.height + rectTabBar.origin.x
            tableView.contentInset = UIEdgeInsetsMake(navigationBarSpace, 0, tabBarSpace, 0)
            addChallengeView.snp.updateConstraints({ (make) in
                make.top.equalTo(navigationBarSpace)
            })
        }
    }

    func setupUI() {
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) /* #000000 */
        tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view)
            make.width.equalTo(view)
            make.bottom.equalTo(view.snp.bottom)
        }

        addChallengeView = UIView()
        addChallengeView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        view.insertSubview(addChallengeView, aboveSubview: tableView)
        addChallengeView.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(64)
            make.width.equalTo(view)
            make.height.equalTo(250)
        }

        challengeTextField = UITextField()
        challengeTextField.accessibilityIdentifier = "challengeTextField"
        challengeTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        challengeTextField.leftViewMode = UITextFieldViewMode.always
        challengeTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        challengeTextField.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        challengeTextField.attributedPlaceholder = NSAttributedString(string: MHClient.AppCopy.pleaseAddAChallenge, attributes: [NSForegroundColorAttributeName: UIColor.black])
        addChallengeView.addSubview(challengeTextField)
        challengeTextField.snp.makeConstraints { (make) in
            make.top.equalTo(addChallengeView)
            make.height.equalTo(50)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        challengeDatePicker = UIDatePicker()
        challengeDatePicker.accessibilityIdentifier = "challengeDatePicker"
        challengeDatePicker.minimumDate = Date().add(minutes: 10)
        addChallengeView.addSubview(challengeDatePicker)
        challengeDatePicker.snp.makeConstraints { (make) in
            make.top.equalTo(challengeTextField.snp.bottom)
            make.height.equalTo(150)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        addChallengeButton = UIButton()
        addChallengeButton.accessibilityIdentifier = "addChallengeButton"
        addChallengeButton.setTitle(MHClient.AppCopy.addChallenge, for: UIControlState())
        addChallengeButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: UIControlState())
        let tapToAddChallenge: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addChallenge(_:)))
        tapToAddChallenge.numberOfTapsRequired = 1
        addChallengeButton.addGestureRecognizer(tapToAddChallenge)
        addChallengeView.addSubview(addChallengeButton)
        addChallengeButton.snp.makeConstraints { (make) in
            make.top.equalTo(challengeDatePicker.snp.bottom)
            make.height.equalTo(50)
            make.width.equalTo(addChallengeView)
            make.centerX.equalTo(addChallengeView)
        }

        dimView = UIView(frame: view.frame)
        dimView.backgroundColor = UIColor.black
        view.insertSubview(dimView, belowSubview: addChallengeView)
        let tapToDismissAddChallengeView: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showOrHideChallengeView))
        tapToDismissAddChallengeView.numberOfTapsRequired = 1
        dimView.addGestureRecognizer(tapToDismissAddChallengeView)

        // Set background View
        layer.frame = view.frame
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor /* #000000 */
        let color2 = UIColor(red: 0.1294, green: 0.1294, blue: 0.1294, alpha: 1.0).cgColor /* #212121 */
        layer.colors = [color1, color2]
        layer.contentsGravity = kCAGravityResize
        view.layer.insertSublayer(layer, below: tableView.layer)

        tableView.allowsMultipleSelection = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(ChallengeViewController.showOrHideChallengeView))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AddOrCancelButton"

        let longTapToEditChallenge: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ChallengeViewController.editChallenge(_:)))
        longTapToEditChallenge.minimumPressDuration = 1.5
        tableView.addGestureRecognizer(longTapToEditChallenge)
    }

    // Initialize CoreData and NSFetchedResultsController

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Challenge")

        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "completed", ascending: true),
            NSSortDescriptor(key: "endDate", ascending: true)
        ]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        return fetchedResultsController
    }()
}

extension ChallengeViewController {

    func showOrHideChallengeView() {
        editMode = editMode ? false : true
        switch editMode {
        case true:
            showAddChallengeView()
        case false:
            HideAddChallengeView()
        }
    }

    func addChallenge(_: UIGestureRecognizer) {

        let challengeDictionary: [String : AnyObject] = [
            "challengeDescription": challengeTextField.text! as AnyObject,
            "completed": 0 as AnyObject,
            "endDate": challengeDatePicker.date as AnyObject
        ]

        guard challengeTextField.text != "" else {
            challengeTextField.attributedPlaceholder = NSAttributedString(string: MHClient.AppCopy.pleaseAddAChallenge, attributes: [NSForegroundColorAttributeName: UIColor.red])
            return
        }

        // Modify Challenge based on Edit mode

        guard currentChallengeToEdit == nil else {
            DispatchQueue.main.async {
                if let challengeToEdit = self.currentChallengeToEdit {
                    challengeToEdit.challengeDescription = self.challengeTextField.text!
                    challengeToEdit.endDate = self.challengeDatePicker.date
                    CoreDataStackManager.sharedInstance.saveContext()
                }
            }
            showOrHideChallengeView()
            return
        }

        DispatchQueue.main.async {
            let test = Challenge(
                challengeDescription: challengeDictionary["challengeDescription"] as! String,
                completed: challengeDictionary["completed"] as! Bool,
                endDate: challengeDictionary["endDate"] as! Date,
                context: self.sharedContext)
            test.uniqueIdentifier = NSUUID().uuidString
            CoreDataStackManager.sharedInstance.saveContext()
        }
        showOrHideChallengeView()
    }

    func editChallenge(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let tapPoint: CGPoint = gestureRecognizer.location(in: tableView)
            let indexPath = tableView.indexPathForRow(at: tapPoint)
            currentChallengeToEdit = fetchedResultsController.object(at: indexPath!) as? Challenge
            showOrHideChallengeView()
        }
    }

    func showAddChallengeView() {
        challengeTextField.text = ""
        challengeDatePicker.minimumDate = Date().add(minutes: 5)
        challengeDatePicker.date = Date().add(minutes: 5)
        
        if currentChallengeToEdit != nil {
            challengeTextField.text = currentChallengeToEdit!.challengeDescription
            challengeDatePicker.date = currentChallengeToEdit!.endDate as Date
            addChallengeButton.setTitle("Modify challenge", for: UIControlState())
        }

        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.addChallengeView.center.y += self.view.bounds.width
            self.dimView.alpha = 0.3
            }, completion: { finished in
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.cancel,
                    target: self,
                    action: #selector(ChallengeViewController.showOrHideChallengeView)
                )
                self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AddOrCancelButton"
        })
    }

    func HideAddChallengeView() {
        if currentChallengeToEdit != nil {
            tableView.setEditing(false, animated: true)
        }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.addChallengeView.center.y -= self.view.bounds.width
            self.dimView.alpha = 0
            }, completion: { finished in
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.add,
                    target: self,
                    action: #selector(ChallengeViewController.showOrHideChallengeView)
                )
                self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AddOrCancelButton"
                self.challengeTextField.resignFirstResponder()
        })
        currentChallengeToEdit = nil
    }
}

extension ChallengeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

extension ChallengeViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title = "You don't have any challenge"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: title, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let description = "Challenge yourself!"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: description, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "iconChallenge")
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        let addChallengeButton = "Add a Challenge"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.callout), NSForegroundColorAttributeName: UIColor.white]
        return NSAttributedString(string: addChallengeButton, attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTap button: UIButton) {
        showOrHideChallengeView()
    }
}


extension ChallengeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo

        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MHClient.CellIdentifier.cellWithReuseIdentifier, for: indexPath) as! challengeTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: challengeTableViewCell, atIndexPath indexPath: IndexPath) {
        let challenge = fetchedResultsController.object(at: indexPath) as! Challenge
        cell.selectionStyle = UITableViewCellSelectionStyle.none

        if challenge.completed {
            cell.backgroundColor = #colorLiteral(red: 0.3003999591, green: 0.851647675, blue: 0.4030759931, alpha: 1)
        } else if challenge.endDate < Date() {
            cell.backgroundColor = #colorLiteral(red: 0.994312346, green: 0.2319896519, blue: 0.1840049326, alpha: 1)
        } else {
            cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
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

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let challenge = fetchedResultsController.object(at: indexPath) as! Challenge
        let cell = tableView.cellForRow(at: indexPath)
        
        let modify = UITableViewRowAction(style: .normal, title: MHClient.AppCopy.modify) { action, index in
            self.currentChallengeToEdit = self.fetchedResultsController.object(at: indexPath) as? Challenge
            self.showOrHideChallengeView()
            
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        modify.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)

        if challenge.completed {
            let delete = UITableViewRowAction(style: .normal, title: MHClient.AppCopy.delete) { action, index in
                self.deleteChallenge(challenge)
            }
            delete.backgroundColor = #colorLiteral(red: 0.994312346, green: 0.2319896519, blue: 0.1840049326, alpha: 1)

            let unComplete = UITableViewRowAction(style: .normal, title: MHClient.AppCopy.unComplete) { action, index in
                self.updateCompleteStatusChallenge(challenge)
                DispatchQueue.main.async {
                    cell?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                    tableView.setEditing(false, animated: true)
                }
            }
            unComplete.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            tableView.deselectRow(at: indexPath, animated: true)
            return [delete, unComplete, modify]
        } else {
            let complete = UITableViewRowAction(style: .normal, title: MHClient.AppCopy.complete) { action, index in
                self.updateCompleteStatusChallenge(challenge)
                DispatchQueue.main.async {
                    cell?.backgroundColor = #colorLiteral(red: 0.3003999591, green: 0.851647675, blue: 0.4030759931, alpha: 1)
                    tableView.setEditing(false, animated: true)
                }
            }
            complete.backgroundColor = #colorLiteral(red: 0.3003999591, green: 0.851647675, blue: 0.4030759931, alpha: 1)

            let delete = UITableViewRowAction(style: .normal, title: MHClient.AppCopy.delete) { action, index in
                self.deleteChallenge(challenge)
            }
            delete.backgroundColor = #colorLiteral(red: 0.994312346, green: 0.2319896519, blue: 0.1840049326, alpha: 1)
            tableView.deselectRow(at: indexPath, animated: true)
            return [delete, complete, modify]
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func addChallengeToCoreData(_ challengeDictionary: [String:AnyObject], challengeRecordID: String) {
        DispatchQueue.main.async {
            let _ = Challenge(
                challengeDescription: challengeDictionary["challengeDescription"] as! String,
                completed: challengeDictionary["completed"] as! Bool,
                endDate: challengeDictionary["endDate"] as! Date,
                context: self.sharedContext)
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func deleteChallenge(_ challenge: Challenge) {
        DispatchQueue.main.async {
            self.sharedContext.delete(challenge)
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func updateCompleteStatusChallenge(_ challenge: Challenge) {
        DispatchQueue.main.async {
            challenge.completed = challenge.completed ? false : true
            CoreDataStackManager.sharedInstance.saveContext()
        }
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
