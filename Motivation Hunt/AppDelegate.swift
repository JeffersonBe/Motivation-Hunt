//
//  AppDelegate.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 23/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData
import Log
import CloudKit
import GoogleAnalytics

let Log = Logger()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        // Push notification setup
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        // Configure Status Bar
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        if let statusBar = UIApplication.sharedApplication().valueForKey("statusBarWindow")?.valueForKey("statusBar") as? UIView {
            statusBar.backgroundColor = UIColor.blackTransparentColor()
        }

        // Configure Google Analytics
        let gai = GAI.sharedInstance()
        gai.trackerWithTrackingId("UA-77655829-1")
        gai.trackUncaughtExceptions = true  // report uncaught exceptions

        #if DEBUG
            gai.logger.logLevel = GAILogLevel.Error
        #else
            gai.logger.logLevel = GAILogLevel.None
            Log.enabled = false
        #endif

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStackManager.sharedInstance.saveContext()
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])

        if cloudKitNotification.notificationType == .Query {
            let queryNotification = cloudKitNotification as! CKQueryNotification

            Log.info(queryNotification)

            if queryNotification.queryNotificationReason == .RecordDeleted {
                // If the record has been deleted in CloudKit then delete the local copy here
                Log.info("RecordDeleted")
                SyncManager.sharedInstance.ChallengeDelete(queryNotification.recordID!)
            } else {
                // If the record has been created or changed, we fetch the data from CloudKit
                let database: CKDatabase
                if queryNotification.isPublicDatabase {
                    database = CKContainer.defaultContainer().publicCloudDatabase
                } else {
                    database = CKContainer.defaultContainer().privateCloudDatabase
                }
                
                database.fetchRecordWithID(queryNotification.recordID!, completionHandler: { (record: CKRecord?, error: NSError?) -> Void in
                    guard error == nil else {
                        Log.error(error)
                        return
                    }

                    switch queryNotification.queryNotificationReason {
                    case .RecordCreated:
                        Log.info("RecordCreated")
                        SyncManager.sharedInstance.ChallengeCreated(record!)
                    case .RecordDeleted:
                        Log.info("RecordDeleted")
                        SyncManager.sharedInstance.ChallengeDelete(record!.recordID)
                    case .RecordUpdated:
                        Log.info("RecordUpdated")
                        SyncManager.sharedInstance.ChallengeUpdated(record!)
                    }
                })
            }
        }
    }
}
