//
//  CoreDataStackManager.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import CoreData
import Ensembles

class CoreDataStackManager: NSObject, CDEPersistentStoreEnsembleDelegate {

    static let sharedInstance = CoreDataStackManager()
    var ensemble : CDEPersistentStoreEnsemble?
    var cloudFileSystem : CDECloudKitFileSystem?

    lazy var storeName : String = {
        return MHClient.Constants.StoreName
    }()

    lazy var sqlName : String = {
        return self.storeName + ".sqlite"
    }()

    lazy var modelURL : NSURL = {
        return NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")!
    }()

    lazy var storeDirectoryURL : NSURL = {
        var directoryURL : NSURL? = nil
        do {
            try directoryURL = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
            directoryURL = directoryURL!.URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!, isDirectory: true)
        } catch {
            NSLog("Unresolved error: Application's document directory is unreachable")
            abort()
        }
        return directoryURL!
    }()

    lazy var storeURL : NSURL = {
        return self.storeDirectoryURL.URLByAppendingPathComponent(self.sqlName)
    }()

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jeffersonbonnaire.Motivation_Hunt" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        return NSManagedObjectModel(contentsOfURL: self.modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var options = [NSObject: AnyObject]()
        options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(bool: true)
        options[NSInferMappingModelAutomaticallyOption] = NSNumber(bool: true)

        var failureReason = "There was an error creating or loading the application's saved data."

        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(self.storeDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Unresolved error: local database storage position is unavailable.")
            abort()
        }

        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                       configuration: nil,
                                                       URL: self.storeURL,
                                                       options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

    func enableEnsemble() {
        #if DEBUG
            CDESetCurrentLoggingLevel(4)
        #else
            CDESetCurrentLoggingLevel(0)
        #endif

        cloudFileSystem = CDECloudKitFileSystem(
            ubiquityContainerIdentifier: MHClient.Constants.CKBaseUrl,
            rootDirectory: nil,
            usePublicDatabase: true,
            schemaVersion: CDECloudKitSchemaVersion.Version1)

        cloudFileSystem?.subscribeForPushNotificationsWithCompletion({ (error) in
            guard error == nil else {
                Log.error("subscribeForPushNotificationsWithCompletion: ", error)
                return
            }
        })

        ensemble = CDEPersistentStoreEnsemble(
            ensembleIdentifier: MHClient.Constants.CKBaseUrl,
            persistentStoreURL: storeURL,
            managedObjectModelURL: modelURL,
            cloudFileSystem: cloudFileSystem!)

        CoreDataStackManager.sharedInstance.ensemble!.delegate = CoreDataStackManager.sharedInstance
        
        ensemble?.leechPersistentStoreWithSeedPolicy(CDESeedPolicy.MergeAllData, completion: { (NSError) in
            Log.info("leechPersistentStoreWithSeedPolicy")
        })
    }

    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWithNotification notification: NSNotification) {
        CoreDataStackManager.sharedInstance.managedObjectContext.performBlockAndWait({ () -> Void in
            CoreDataStackManager.sharedInstance.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        })

        if notification == true {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.02 * Double(NSEC_PER_MSEC))), dispatch_get_main_queue(), {
                Log.info("Database was updated from iCloud")
                CoreDataStackManager.sharedInstance.saveContext()
                NSNotificationCenter.defaultCenter().postNotificationName("DB_UPDATED", object: nil)
            })
        }
    }

    func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble, globalIdentifiersForManagedObjects objects: [NSManagedObject]) -> [NSObject] {
        return (objects as NSArray).valueForKeyPath("uniqueIdentifier") as! [NSObject]
    }

    func syncWithCompletion(completion: (() -> Void)!) {

        guard ensemble?.leeched == true else {
            ensemble!.leechPersistentStoreWithCompletion({ (error:NSError?) -> Void in
                if let error = error {
                    switch (error.code) {
                    case 103:
                        self.performSelector(
                            #selector(
                                CoreDataStackManager.sharedInstance.syncWithCompletion(_:)),
                            withObject: nil,
                            afterDelay: 1.0)
                        return
                    default:
                        Log.error("Error in leechPersistentStoreWithCompletion:", error)
                        return
                    }
                }

                self.performSelector(#selector(CoreDataStackManager.sharedInstance.syncWithCompletion(_:)), withObject: nil, afterDelay: 1.0)

                if let c = completion {
                    c()
                }
            })
            return
        }

        ensemble!.mergeWithCompletion({ (error:NSError?) -> Void in
            if let error = error {
                switch (error.code) {
                case 103:
                        self.performSelector(#selector(CoreDataStackManager.sharedInstance.syncWithCompletion(_:)), withObject: nil, afterDelay: 1.0)
                        Log.error("Error case 103:", error)
                        return
                default:
                        Log.error("Error in mergeWithCompletion:", error)
                        return
                }
            }

            if let c = completion {
                c()
            }
        })
    }
}