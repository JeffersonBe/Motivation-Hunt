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

let Log = Logger(formatter: .detailed, theme: .tomorrowNight)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let pinPointKit = PinpointKit(configuration: Configuration(appearance: InterfaceCustomization.Appearance.init(tintColor: UIColor.black), feedbackConfiguration: FeedbackConfiguration(recipients: ["jefferson.bonnaire+motivationHunt@gmail.com"]))
    )
    
    enum ShortcutIdentifier: String {
        case OpenFavorites
        case OpenChallenge
        
        init?(fullIdentifier: String) {
            guard let shortIdentifier = fullIdentifier.components(separatedBy: ".").last else {
                return nil
            }
            self.init(rawValue: shortIdentifier)
        }
    }
    
    // Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"

    var window: UIWindow? = ShakeDetectingWindow(frame: UIScreen.main.bounds,
                                                 delegate: AppDelegate.pinPointKit)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true

        let _ : CoreDataStackManager = CoreDataStackManager.sharedInstance
        CoreDataStackManager.sharedInstance.saveContext()
        CoreDataStackManager.sharedInstance.enableEnsemble()
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            _ = handleShortcut(shortcutItem: shortcutItem)
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }

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

        return shouldPerformAdditionalDelegateHandling
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
        
        guard let shortcut = launchedShortcutItem else { return }
        
        _ = handleShortcut(shortcutItem: shortcut)
        
        launchedShortcutItem = nil
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
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem: shortcutItem))
    }
    
    
    func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcutItem.type
        
        guard let shortcutIdentifier = ShortcutIdentifier(fullIdentifier: shortcutType) else {
            return false
        }
        
        return selectTabBarItemForIdentifier(identifier: shortcutIdentifier)
    }
    
    func selectTabBarItemForIdentifier(identifier: ShortcutIdentifier) -> Bool {
        
        guard let tabBarController = self.window?.rootViewController as? UITabBarController else {
            return false
        }
        
        switch (identifier) {
        case .OpenFavorites:
            tabBarController.selectedIndex = 1
            return true
        case .OpenChallenge:
            tabBarController.selectedIndex = 2
            if let topController = window?.visibleViewController() {
                if topController.isKind(of: ChallengeViewController.self) {
                   let challengeViewController = topController as! ChallengeViewController
                    challengeViewController.viewDidLoad()
                    challengeViewController.editMode = false
                    challengeViewController.showOrHideChallengeView()
                }
            }
            return true
        }
    }
}
