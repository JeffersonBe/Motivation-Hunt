//
//  AppDelegate.swift
//  Motivation Hunt TV
//
//  Created by Jefferson Bonnaire on 12/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import Log

let Log = Logger(formatter: .detailed, theme: .tomorrowNight)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CoreDataStack.shared.saveContext()
        CoreDataStack.shared.enableEnsemble()
        
        // Listen for local saves, and trigger merges
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.localSaveOccured(_:)), name: NSNotification.Name.CDEMonitoredManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.cloudDataDidDownload(_:)), name:NSNotification.Name.CDEICloudFileSystemDidDownloadFiles, object:nil)
        
        // Push notification setup
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        application.registerForRemoteNotifications()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        CoreDataStack.shared.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        let identifier : UIBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        CoreDataStack.shared.saveContext()
        CoreDataStack.shared.syncWithCompletion( { () -> Void in
            UIApplication.shared.endBackgroundTask(identifier)
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        CoreDataStack.shared.syncWithCompletion(nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        CoreDataStack.shared.syncWithCompletion(nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    // MARK: Notification Handlers
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log.info("didReceiveRemoteNotification")
        let backgroundIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        CoreDataStack.shared.syncWithCompletion({
            UIApplication.shared.endBackgroundTask(backgroundIdentifier)
            completionHandler(UIBackgroundFetchResult.newData)
        })
    }
    
    func localSaveOccured(_ notif: Notification) {
        Log.info("localSaveOccured")
        CoreDataStack.shared.syncWithCompletion(nil)
    }
    
    func cloudDataDidDownload(_ notif: Notification) {
        Log.info("cloudDataDidDownload")
        CoreDataStack.shared.syncWithCompletion(nil)
    }
}

