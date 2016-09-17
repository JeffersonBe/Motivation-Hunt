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

//    let pinPointKit = PinpointKit(configuration: Configuration(
//        feedbackRecipients: ["Jefferson.bonnaire+motivationHunt@gmail.com"],
//        appearance: InterfaceCustomization.Appearance.init(tintColor: UIColor.blackColor())
//        ))

//    internal lazy var window: UIWindow? = ShakeDetectingWindow(frame: UIScreen.mainScreen.bounds, delegate: self.pinPointKit)
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let _ : CoreDataStackManager = CoreDataStackManager.sharedInstance
        CoreDataStackManager.sharedInstance.saveContext()
        CoreDataStackManager.sharedInstance.enableEnsemble()

        // Listen for local saves, and trigger merges
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.localSaveOccured(_:)), name: NSNotification.Name.CDEMonitoredManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.cloudDataDidDownload(_:)), name:NSNotification.Name.CDEICloudFileSystemDidDownloadFiles, object:nil)

        // Push notification setup
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        application.registerForRemoteNotifications()

        // Configure Status Bar
        UIApplication.shared.statusBarStyle = .lightContent

        // Configure Google Analytics
        let gai = GAI.sharedInstance()
        _ = gai?.tracker(withTrackingId: "UA-77655829-1")
        gai?.trackUncaughtExceptions = true  // report uncaught exceptions

        // Logging Mechanism
        #if DEBUG
            gai?.logger.logLevel = GAILogLevel.error
        #else
            Log.enabled = false
            gai?.logger.logLevel = GAILogLevel.none
        #endif

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        let identifier : UIBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        CoreDataStackManager.sharedInstance.saveContext()
        CoreDataStackManager.sharedInstance.syncWithCompletion( { () -> Void in
            UIApplication.shared.endBackgroundTask(identifier)
        })

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStackManager.sharedInstance.saveContext()
    }

    // MARK: Notification Handlers

    func localSaveOccured(_ notif: Notification) {
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    func cloudDataDidDownload(_ notif: Notification) {
        CoreDataStackManager.sharedInstance.syncWithCompletion(nil)
    }

    // MARK: Notification Handlers

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let backgroundIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        CoreDataStackManager.sharedInstance.syncWithCompletion({
            UIApplication.shared.endBackgroundTask(backgroundIdentifier)
            completionHandler(UIBackgroundFetchResult.newData)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
}
