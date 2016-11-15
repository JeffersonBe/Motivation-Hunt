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

    lazy var modelURL : URL = {
        return Bundle.main.url(forResource: self.storeName, withExtension: "momd")!
    }()

    lazy var storeDirectoryURL : URL = {
        var directoryURL : URL? = nil
        do {
            try directoryURL = FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            directoryURL = directoryURL!.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
        } catch {
            fatalError("Unresolved error: Application's document directory is unreachable")
        }
        return directoryURL!
    }()

    lazy var storeURL : URL = {
        return self.storeDirectoryURL.appendingPathComponent(self.sqlName)
    }()

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jeffersonbonnaire.Motivation_Hunt" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        return NSManagedObjectModel(contentsOf: self.modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var options = [AnyHashable: Any]()
        options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(value: true as Bool)
        options[NSInferMappingModelAutomaticallyOption] = NSNumber(value: true as Bool)

        var failureReason = "There was an error creating or loading the application's saved data."

        do {
            try FileManager.default.createDirectory(at: self.storeDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Unresolved error: local database storage position is unavailable.")
        }

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                       configurationName: nil,
                                                       at: self.storeURL,
                                                       options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            fatalError("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
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
            schemaVersion: CDECloudKitSchemaVersion.version1)

        cloudFileSystem?.subscribeForPushNotifications(completion: { (error) in
            guard error == nil else {
                Log.error("subscribeForPushNotificationsWithCompletion: ", error!)
                return
            }
        })

        ensemble = CDEPersistentStoreEnsemble(
            ensembleIdentifier: MHClient.Constants.CKBaseUrl,
            persistentStore: storeURL,
            managedObjectModelURL: modelURL,
            cloudFileSystem: cloudFileSystem!)

        CoreDataStackManager.sharedInstance.ensemble!.delegate = CoreDataStackManager.sharedInstance
        
        ensemble?.leechPersistentStore(with: CDESeedPolicy.mergeAllData, completion: { (error) in
            guard error == nil else {
                Log.info("leechPersistentStoreWithSeedPolicy :", error!)
                return
            }
        })
    }

    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        CoreDataStackManager.sharedInstance.managedObjectContext.performAndWait({ () -> Void in
            CoreDataStackManager.sharedInstance.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        })

        if notification.object != nil {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.02 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC), execute: {
                CoreDataStackManager.sharedInstance.saveContext()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DB_UPDATED"), object: nil)
            })
        }
    }

    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, globalIdentifiersFor objects: [NSManagedObject]) -> [NSObject] {
        return (objects as NSArray).value(forKeyPath: "uniqueIdentifier") as! [NSObject]
    }

    func syncWithCompletion(_ completion: (() -> Void)!) {

        guard ensemble?.isLeeched == true else {
            ensemble!.leechPersistentStore(completion: { (error) -> Void in
                if let error = error {
                    switch (error._code) {
                    case 103:
                        self.perform(
                            #selector(
                                CoreDataStackManager.sharedInstance.syncWithCompletion(_:)),
                            with: nil,
                            afterDelay: 1.0)
                        return
                    default:
                        Log.error("Error in leechPersistentStoreWithCompletion:", error)
                        return
                    }
                }

                self.perform(#selector(CoreDataStackManager.sharedInstance.syncWithCompletion(_:)), with: nil, afterDelay: 1.0)

                if let c = completion {
                    c()
                }
            })
            return
        }

        ensemble!.merge(completion: { (error) -> Void in
            if let error = error {
                switch (error._code) {
                case 103:
                    self.perform(#selector(CoreDataStackManager.sharedInstance.syncWithCompletion(_:)), with: nil, afterDelay: 1.0)
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
