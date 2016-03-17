//
//  LoginViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 16/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Log

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        // Check if connected to network, if not we show the app because we cannot check if the iCloud has changed
        guard Reachability.connectedToNetwork() else {
            showApp()
            return
        }

        // Check User account is already logged
        guard let currentUserRecordID = NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") else {
            iCloudLoginAction()
            return
        }

        // Check currentUserRecordID is the same as the current iCloud User Account
        CloudKitHelper.sharedInstance.getUser({ (success, userRecordID) in
            guard success && currentUserRecordID as! String == userRecordID else {
                self.throwUserChoiceOfKeepingCurrentOrNewIcloudRecord()
                return
            }
            self.showApp()
        })
    }

    func iCloudLoginAction() {
        iCloudLogin({ (success) -> () in
            guard success else {
                self.throwIcloudAccountAuthenficationError()
                return
            }
                self.showApp()
        })
    }

    // Nested CloudKit requests for permission; for getting user permission and user information.
    func iCloudLogin(completionHandler: (success: Bool) -> ()) {
        CloudKitHelper.sharedInstance.getUser({ (success, userRecordID) in
            guard success else {
                self.throwIcloudAccountAuthenficationError()
                return
            }
                CloudKitHelper.sharedInstance.getUserInfo(userRecordID, completionHandler: { (success, firstName) in
                    NSUserDefaults.standardUserDefaults().setObject(userRecordID as String, forKey: "currentUserRecordID")
                    NSUserDefaults.standardUserDefaults().setObject(firstName as String, forKey: "currentUserFirstName")
                    completionHandler(success: true)
                })
        })
    }

    func showApp() {
        dispatch_async(dispatch_get_main_queue()) {
            let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("tabBarController")
            self.presentViewController(viewController, animated: true, completion: nil)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }

    func throwIcloudAccountAuthenficationError() {
        let iCloudAlert = UIAlertController(title: "Authentification Error", message: "We could't log you in. Please check your iCloud account.", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK I'm going to fix that", style: UIAlertActionStyle.Default, handler: nil)

        iCloudAlert.addAction(okAction)
        self.presentViewController(iCloudAlert, animated: true, completion: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func throwUserChoiceOfKeepingCurrentOrNewIcloudRecord() {
        let currentUserFirstName = NSUserDefaults.standardUserDefaults().objectForKey("currentUserFirstName")

        let alertController = UIAlertController(title: "Authentification Error", message: "Your iCloud account isn't \(currentUserFirstName)'s account. Please choose one of them", preferredStyle: .Alert)

        let keepCurrentAppAccount = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            self.throwInformationAboutKeepingCurrentAppAccount()
        }

        let keepCurrentIcloudAccount = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            self.throwInformationAboutKeepingCurrentIcloudAccount()
        }

        alertController.addAction(keepCurrentAppAccount)
        alertController.addAction(keepCurrentIcloudAccount)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func throwInformationAboutKeepingCurrentAppAccount() {
        let currentUserFirstName = NSUserDefaults.standardUserDefaults().objectForKey("currentUserFirstName")

        // TODO: Change text when user choose to keep App iCloud Account instead of current Icloud Account
        let alertController = UIAlertController(title: "Authentification Error", message: "Your iCloud account isn't \(currentUserFirstName)'s account. Please choose one of them", preferredStyle: .Alert)

        let OkAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            // TODO: Implement when user choose to keep App iCloud Account instead of current Icloud Account
        }

        let CancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            self.throwUserChoiceOfKeepingCurrentOrNewIcloudRecord()
        }

        alertController.addAction(OkAction)
        alertController.addAction(CancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func throwInformationAboutKeepingCurrentIcloudAccount() {
        let currentUserFirstName = NSUserDefaults.standardUserDefaults().objectForKey("currentUserFirstName")

        // TODO: Change text when user choose to keep current Icloud Account instead of App iCloud Account
        let alertController = UIAlertController(title: "Authentification Error", message: "Your iCloud account isn't \(currentUserFirstName)'s account. Please choose one of them", preferredStyle: .Alert)

        let OkAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            // TODO: Implement when user choose to keep current Icloud Account instead of App iCloud Account
        }

        let CancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            self.throwUserChoiceOfKeepingCurrentOrNewIcloudRecord()
        }

        alertController.addAction(OkAction)
        alertController.addAction(CancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
