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
import Log
import Async

class LoginViewController: UIViewController {

    var currentUserRecordID: String!
    var currentUserFirstName: String!

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

                if (NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") != nil) {
                    guard self.currentUserRecordID == userRecordID else
                    {
                        let alertViewIcloudNotSame = UIAlertController(title: "You've changed your account", message: "To keep using your favourites and challenge, please use \(self.currentUserFirstName)'s account", preferredStyle: .Alert)
                        let returnUserToIcloudSettings = UIAlertAction(title: "Ok got it", style: .Default, handler: { UIAlertAction in
                            UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=CASTLE")!)
                        })
                        let useNewAccount = UIAlertAction(title: "Ok got it", style: .Default, handler: { UIAlertAction in
                            // TODO: Delete everything in database and redirect user to app
                        })
                        alertViewIcloudNotSame.addAction(returnUserToIcloudSettings)
                        alertViewIcloudNotSame.addAction(useNewAccount)
                        Async.main {
                            self.presentViewController(alertViewIcloudNotSame, animated: true, completion: nil)
                        }
                        return
                    }
                }

                Async.background {
                    NSUserDefaults.standardUserDefaults().setObject(userRecordID! as String, forKey: "currentUserRecordID")
                    self.currentUserRecordID = NSUserDefaults.standardUserDefaults().objectForKey("currentUserRecordID") as! String
                    }.background {
                        CloudKitHelper.sharedInstance.getUserInfo(self.currentUserRecordID, completionHandler: { (success, error, firstName) in
                            guard error == nil else {
                                let alertViewUnableToGetUserInfo = UIAlertController(title: error?.localizedDescription, message: error?.localizedFailureReason, preferredStyle: .Alert)
                                let returnUserToIcloudSettings = UIAlertAction(title: "Ok, call me BOSS now!", style: .Default, handler: { UIAlertAction in
                                    Async.userInteractive {
                                        self.showApp()
                                        NSUserDefaults.standardUserDefaults().setObject("BOSS" as String, forKey: "currentUserFirstName")
                                    }
                                })
                                alertViewUnableToGetUserInfo.addAction(returnUserToIcloudSettings)
                                Async.main {
                                    self.presentViewController(alertViewUnableToGetUserInfo, animated: true, completion: nil)
                                }
                                return
                            }
                            NSUserDefaults.standardUserDefaults().setObject(firstName as String, forKey: "currentUserFirstName")
                        })
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
