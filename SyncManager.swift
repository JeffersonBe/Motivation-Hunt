//
//  SyncManager.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 30/04/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import CoreData
import CloudKit
import Async

class SyncManager {
    static var sharedInstance = SyncManager()

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }

    init() {
        
    }

    lazy var challengeFetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Challenge")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completed", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }()

    func ChallengeCreated(record: CKRecord) {
        Async.main {
        let _ = Challenge(challengeDescription: record.valueForKey("challengeDescription") as! String,
                          completed: record.valueForKey("completed") as! Bool,
                          endDate: record.valueForKey("endDate") as! NSDate,
                          challengeRecordID: record.recordID.recordName,
                          context: self.sharedContext)
        CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    func ChallengeDelete(record: CKRecordID) {

        let deleteObject = returnChallengeObjet(record.recordName)

        do {
            try deleteObject.performFetch()
        } catch let error as NSError {
            Log.error("Error: \(error.localizedDescription)")
        }

        if deleteObject.fetchedObjects!.count != 0 {
            sharedContext.deleteObject(deleteObject.fetchedObjects?.first as! Challenge)
        }
    }

    func ChallengeUpdated(record: CKRecord) {
        let updateObject = returnChallengeObjet(record.recordID.recordName)

        do {
            try updateObject.performFetch()
        } catch let error as NSError {
            Log.error("Error: \(error.localizedDescription)")
        }

        if updateObject.fetchedObjects!.count != 0 {
            Async.main {
                let challenge = updateObject.fetchedObjects?.first as! Challenge
                challenge.challengeDescription = record.valueForKey("challengeDescription") as! String
                challenge.completed = record.valueForKey("completed") as! Bool
                challenge.endDate = record.valueForKey("endDate") as! NSDate

                CoreDataStackManager.sharedInstance.saveContext()
            }
        }
    }

    func returnChallengeObjet(challengeRecordID: String) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "Challenge")
        let predicate = NSPredicate(format: "challengeRecordID == %@", "\(challengeRecordID)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completed", ascending: true)]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }
}
