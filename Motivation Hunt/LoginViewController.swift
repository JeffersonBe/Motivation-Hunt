//
//  LoginViewController.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 16/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import Async
import GoogleAnalytics

class LoginViewController: UIViewController {

    var currentUserRecordID: String!

    deinit {
        NSNotificationCenter
            .defaultCenter()
            .removeObserver(self,
                            name: UIApplicationWillEnterForegroundNotification,
                            object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        // Check is user already log in
        if let userRecordID = NSUserDefaults.standardUserDefaults()
            .objectForKey("currentUserRecordID") {
            currentUserRecordID = userRecordID as! String
            showApp()
        }

        loginIcloudUser()


        // Subscribe to Notification is case user leave login session
        NSNotificationCenter
            .defaultCenter()
            .addObserverForName(
            UIApplicationWillEnterForegroundNotification,
            object: nil,
            queue: nil) { (NSNotification) in
            self.loginIcloudUser()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "LoginViewController")

        let builder: NSObject = GAIDictionaryBuilder.createScreenView().build()
        tracker.send(builder as! [NSObject : AnyObject])
    }

    func loginIcloudUser() {
        let group = AsyncGroup()

        // First check if iCloud is available
        guard CloudKitHelper.sharedInstance.isIcloudAvailable() == true else {
            showAlert(MHClient.AppCopy.icloudAccountTitleError, message: MHClient.AppCopy.icloudAccountMessageError)
            return
        }

        // Then we check if the user Granted permission to the app
        group.userInteractive() {
            CloudKitHelper.sharedInstance.requestPermission({ (granted, error) in
                guard granted else {
                    Log.error(error)
                    self.showAlert(error?.localizedDescription, message: error?.localizedRecoverySuggestion)
                    return
                }
            })
        }

        // And get the user information to track change of user ID
        group.background {
            CloudKitHelper.sharedInstance.getUser({ (success, userRecordID, error) in
                guard success && userRecordID == userRecordID else {
                    Log.error(error)
                    Async.main {
                        guard self.presentedViewController?.isBeingPresented() == true else {
                            self.showAlert(error?.domain, message: error?.localizedDescription)
                            return
                        }
                    }
                    return
                }

                Async.background {
                    NSUserDefaults.standardUserDefaults().setObject(userRecordID! as String, forKey: "currentUserRecordID")
                    self.currentUserRecordID = NSUserDefaults
                        .standardUserDefaults()
                        .objectForKey("currentUserRecordID") as! String
                }
                self.showApp()
            })
        }
    }

    func showApp() {
        UIApplication
            .sharedApplication()
            .networkActivityIndicatorVisible = false
        let viewController = storyboard!.instantiateViewControllerWithIdentifier("tabBarController")
        Async.main {
            self.presentViewController(
                viewController,
                animated: true,
                completion: nil)
        }
    }

    func showAlert(title: String?, message: String?){
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert)

        if message == "The Internet connection appears to be offline." {
            let returnUserToNetworkSettings = UIAlertAction(
                title: "Turn on my Internet connection",
                style: .Default,
                handler: { UIAlertAction in
                    let url = NSURL(string: "prefs:root=General&path=Network")
                    if UIApplication.sharedApplication().canOpenURL(url!) {
                        UIApplication.sharedApplication().openURL(url!)
                    }
            })
            alert.addAction(returnUserToNetworkSettings)
        } else {
            let returnUserToIcloudSettings = UIAlertAction(
                title: "Add an iCloud account",
                style: .Default,
                handler: { UIAlertAction in
                    let url = NSURL(string: "prefs:root=CASTLE")
                    if UIApplication.sharedApplication().canOpenURL(url!) {
                        UIApplication.sharedApplication().openURL(url!)
                    }
            })
            alert.addAction(returnUserToIcloudSettings)
        }
        Async.main {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
