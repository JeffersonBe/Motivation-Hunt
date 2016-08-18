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
import PinpointKit

let Log = Logger()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // var window: UIWindow?
    let pinPointKit = PinpointKit(configuration: Configuration(
        feedbackRecipients: ["Jefferson.bonnaire+motivationHunt@gmail.com"],
        appearance: InterfaceCustomization.Appearance.init(tintColor: UIColor.blueColor())
        ))
    lazy var window: UIWindow? = ShakeDetectingWindow(frame: UIScreen.mainScreen().bounds, delegate: self.pinPointKit)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        let _ : CoreDataStackManager = CoreDataStackManager.sharedInstance
        CoreDataStackManager.sharedInstance.saveContext()
        CoreDataStackManager.sharedInstance.enableEnsemble()

        // Listen for local saves, and trigger merges
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.localSaveOccured(_:)), name: CDEMonitoredManagedObjectContextDidSaveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.cloudDataDidDownload(_:)), name:CDEICloudFileSystemDidDownloadFilesNotification, object:nil)

        // Push notification setup
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        application.registerForRemoteNotifications()

        // Configure Status Bar
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        if let statusBar = UIApplication
            .sharedApplication()
            .valueForKey("statusBarWindow")?
            .valueForKey("statusBar") as? UIView {
            statusBar.backgroundColor = UIColor.blackTransparentColor()
        }

        // Configure Google Analytics
        let gai = GAI.sharedInstance()
        gai.trackerWithTrackingId("UA-77655829-1")
        gai.trackUncaughtExceptions = true  // report uncaught exceptions

        // Logging Mechanism
        #if DEBUG
            gai.logger.logLevel = GAILogLevel.Error
        #else
            Log.enabled = false
            gai.logger.logLevel = GAILogLevel.None
        #endif

        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        let identifier : UIBackgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
        CoreDataStackManager.sharedInstance.saveContext()
        CoreDataStackManager.sharedInstance.syncWithCompletion( { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(identifier)
        })

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStackManager.sharedInstance.saveContext()
    }

    // MARK: Notification Handlers

    func localSaveOccured(notif: NSNotification) {
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func cloudDataDidDownload(notif: NSNotification) {
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    // MARK: Notification Handlers

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let backgroundIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)

        CoreDataStackManager.sharedInstance.syncWithCompletion({
            UIApplication.sharedApplication().endBackgroundTask(backgroundIdentifier)
            completionHandler(UIBackgroundFetchResult.NewData)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
}
