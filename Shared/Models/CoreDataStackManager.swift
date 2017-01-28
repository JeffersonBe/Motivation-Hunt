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
import DeviceKit

class CoreDataStack: NSObject {
    
    static let shared = CoreDataStack()
    
    // MARK: Initialization
    private override init() { }
    
    var ensemble : CDEPersistentStoreEnsemble?
    var cloudFileSystem : CDECloudKitFileSystem?
    
    var storeDirectoryURL: URL {
        do {
            var directoryToWriteFiles: FileManager.SearchPathDirectory
            if Device().isPhone || Device().isPad {
                directoryToWriteFiles = .applicationSupportDirectory
            } else {
                // tvOS uses the cache directory to write the sqlite files
                directoryToWriteFiles = .cachesDirectory
            }
            
            let storeDirectoryURL = try FileManager.default.url(
                for: directoryToWriteFiles,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
            return storeDirectoryURL
        } catch {
            fatalError("Couldn't find storeDirectoryURL")
        }
    }
    
    var defaultDirectoryURL: URL {
        guard let defaultDirectoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MHClient.Constants.securityApplicationGroupIdentifier) else {
            fatalError("Couldn't find defaultDirectoryURL")
        }

        return defaultDirectoryURL
    }
    
    var storeURL: URL {
        return self.storeDirectoryURL.appendingPathComponent(MHClient.Constants.storeSQLITENameAndExtension)
    }
    
    var managedObjectModelURL: URL {
        guard let managedObjectModelURL = Bundle.main.url(forResource: MHClient.Constants.StoreName, withExtension: MHClient.Constants.StoreMomdExtension) else  {
            fatalError("Couldn't find managedObjectModelURL")
        }
        return managedObjectModelURL
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: MHClient.Constants.StoreName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

extension CoreDataStack: CDEPersistentStoreEnsembleDelegate {
    
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

        ensemble = CDEPersistentStoreEnsemble(
            ensembleIdentifier: MHClient.Constants.StoreName,
            persistentStore: storeURL,
            persistentStoreOptions: nil,
            managedObjectModelURL: managedObjectModelURL,
            cloudFileSystem: cloudFileSystem!,
            localDataRootDirectoryURL: storeDirectoryURL)
        
        CoreDataStack.shared.ensemble!.delegate = self
        
        ensemble!.leechPersistentStore(with: CDESeedPolicy.mergeAllData, completion: { (error) in
            guard error == nil else {
                Log.info("leechPersistentStoreWithSeedPolicy :", error!)
                return
            }
        })
        
        cloudFileSystem!.subscribeForPushNotifications(completion: { (error) in
            guard error == nil else {
                Log.error("subscribeForPushNotificationsWithCompletion: ", error!)
                return
            }
        })
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        CoreDataStack.shared.persistentContainer.viewContext.performAndWait({ () -> Void in
            CoreDataStack.shared.persistentContainer.viewContext.mergeChanges(fromContextDidSave: notification)
        })
        
        if notification.object != nil {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.02 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC), execute: {
                CoreDataStack.shared.saveContext()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DB_UPDATED"), object: nil)
            })
        }
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, globalIdentifiersFor objects: [NSManagedObject]) -> [NSObject] {
        return (objects as NSArray).value(forKeyPath: "uniqueIdentifier") as! [NSObject]
    }
    
    func syncWithCompletion(_ completion: ((Void) -> Void)?) {
        if !ensemble!.isLeeched {
            ensemble!.leechPersistentStore { error in
                guard error == nil else {
                    Log.error(error!)
                    return
                }
                if let c = completion { c() }
            }
        } else {
            ensemble!.merge { error in
                guard error == nil else {
                    Log.error(error!)
                    return
                }
                if let c = completion { c() }
            }
        }
    }
}
