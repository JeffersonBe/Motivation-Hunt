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

class LoginViewController: UIViewController {

    var currentUserRecordID: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if (NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") != nil) {
            currentUserRecordID = NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") as! String
        }
        // Check if connected to network, if not we show the app because we cannot check if the iCloud has changed
        guard Reachability.connectedToNetwork() else {
            showApp()
            return
        }

        let group = AsyncGroup()

        // We check if the user Granted permission to the app
        group.userInteractive() {
            CloudKitHelper.sharedInstance.requestPermission({ (granted, error) in
                guard granted else {
                    Async.main {
                        let alertViewIcloudNotGranted = UIAlertController(title: error?.localizedDescription, message: error?.localizedFailureReason, preferredStyle: .Alert)
                        let returnUserToIcloudSettings = UIAlertAction(title: "Redirect me to icloud settings", style: .Default, handler: { UIAlertAction in
                            Async.userInteractive {
                                UIApplication.sharedApplication()
                                    .openURL(NSURL(string:"prefs:root=CASTLE")!)
                            }
                        })
                        alertViewIcloudNotGranted.addAction(returnUserToIcloudSettings)
                        self.presentViewController(alertViewIcloudNotGranted, animated: true, completion: nil)
                    }
                    return
                }
            })
        }

        // We get the user information to track change of user ID
        group.background {
            CloudKitHelper.sharedInstance.getUser({ (success, userRecordID, error) in
                guard success && userRecordID == userRecordID else {
                    let alertViewIcloudNotGranted = UIAlertController(title: error?.localizedDescription, message: error?.localizedFailureReason, preferredStyle: .Alert)
                    let returnUserToIcloudSettings = UIAlertAction(title: "Fix icloud", style: .Default, handler: { UIAlertAction in
                        Async.userInteractive {
                            UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=CASTLE")!)
                        }
                    })
                    alertViewIcloudNotGranted.addAction(returnUserToIcloudSettings)
                    Async.main {
                        self.presentViewController(alertViewIcloudNotGranted, animated: true, completion: nil)
                    }
                    return
                }

                Async.background {
                    NSUserDefaults.standardUserDefaults().setObject(userRecordID! as String, forKey: "currentUserRecordID")
                    self.currentUserRecordID = NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") as! String
                    }.main {
                        self.showApp()
                }
            })
        }
    }

    func showApp() {
        let viewController = self.storyboard!.instantiateViewControllerWithIdentifier("tabBarController")
        self.presentViewController(viewController, animated: true, completion: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
