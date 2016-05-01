//
//  CloudKitHelper.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 13/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import CloudKit
import Log

enum RecordType: String {
    case MotivationFeedItem = "MotivationFeedItem"
    case Challenge = "Challenge"
}

enum MotivationFeedItemKey: String {
    case itemID = "itemID"
    case itemTitle = "itemTitle"
    case itemDescription = "itemDescription"
    case itemThumbnailsUrl = "itemThumbnailsUrl"
    case saved = "saved"
    case addedDate = "addedDate"
    case itemRecordID = "itemRecordID"
}

enum ChallengeKey: String {
    case challengeDescription = "challengeDescription"
    case completed = "completed"
    case endDate = "endDate"
    case challengeRecordID = "challengeRecordID"
}

class CloudKitHelper {
    var container: CKContainer
    var publicDB: CKDatabase
    let privateDB: CKDatabase

    // MARK: - Shared Instance
    static var sharedInstance = CloudKitHelper()

    typealias CompletionHander = (success: Bool, record: CKRecord!, error: NSError?) -> Void

    let Log = Logger()

    init() {
        container = CKContainer(identifier: "iCloud.com.jeffersonbonnaire.motivationhunt")
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    // MARK: User

    func requestPermission(completionHandler: (granted: Bool, error: NSError?) -> ()) {
        container.requestApplicationPermission(CKApplicationPermissions.UserDiscoverability, completionHandler: { applicationPermissionStatus, error in
            guard applicationPermissionStatus == CKApplicationPermissionStatus.Granted else {
                self.Log.warning(error, applicationPermissionStatus)
                completionHandler(granted: false, error: error)
                return
            }
            completionHandler(granted: true, error: nil)
        })
    }

    func accountStatus(completionHandler: (accountStatus: CKAccountStatus, error: NSError?)-> ()) {
        container.accountStatusWithCompletionHandler { (CKAccountStatus, error) in
            guard error == nil else {
                self.Log.warning(error, CKAccountStatus)
                completionHandler(accountStatus: CKAccountStatus, error: error)
                return
            }
            completionHandler(accountStatus: CKAccountStatus, error: error)
        }
    }

    func getUser(completionHandler: (success: Bool, userRecordID: String?, error: NSError?) -> ()) {
        container.fetchUserRecordIDWithCompletionHandler { (recordID, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, userRecordID: "", error: error)
                return
            }
            completionHandler(success: true, userRecordID: recordID?.recordName, error: nil)
        }
    }

    // MARK: - General call
    func fetchUserRecord(recordID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(recordID) { (record, error) -> Void in
            guard record == record && error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }
}

extension CloudKitHelper {

    func fetchMotivationFeedItem(completionHandler: (success: Bool?, record: [CKRecord]?, error: NSError?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "\(RecordType.MotivationFeedItem)", predicate: predicate)
        privateDB.performQuery(query, inZoneWithID: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record!, error: nil)
        }
    }

    // MARK: - Favorites
    func savedMotivationItem(itemTitle: String, itemDescription: String, itemID: String, itemThumbnailsUrl: String, saved: Bool, addedDate: NSDate, completionHandler: CompletionHander) {
        let motivationItem = CKRecord(recordType: "\(RecordType.MotivationFeedItem)")

        motivationItem.setValue(itemID, forKey: "\(MotivationFeedItemKey.itemID)")
        motivationItem.setValue(itemTitle, forKey: "\(MotivationFeedItemKey.itemTitle)")
        motivationItem.setValue(itemDescription, forKey: "\(MotivationFeedItemKey.itemDescription)")
        motivationItem.setValue(itemThumbnailsUrl, forKey: "\(MotivationFeedItemKey.itemThumbnailsUrl)")
        motivationItem.setValue(saved, forKey: "\(MotivationFeedItemKey.saved)")
        motivationItem.setValue(addedDate, forKey: "\(MotivationFeedItemKey.addedDate)")

        privateDB.saveRecord(motivationItem) { (record, error) in
            guard record == record && error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    func fetchFavorites(completionHandler: (success: Bool?, record: [CKRecord]?, error: NSError?) -> Void) {
        let predicate = NSPredicate(format: "\(MotivationFeedItemKey.saved) == 1")
        let query = CKQuery(recordType: "\(RecordType.MotivationFeedItem)", predicate: predicate)
        privateDB.performQuery(query, inZoneWithID: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record!, error: nil)
        }
    }

    func updateFavorites(favoritesID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(favoritesID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }

            let favorites = record

            if favorites!.valueForKey("\(MotivationFeedItemKey.saved)") as! Int == 0 {
                favorites!.setValue(1, forKey: "\(MotivationFeedItemKey.saved)")
            } else {
                favorites!.setValue(0, forKey: "\(MotivationFeedItemKey.saved)")
            }

            self.privateDB.saveRecord(favorites!) { (record, error) in
                guard error == nil else {
                    self.Log.warning(error)
                    completionHandler(success: false, record: nil, error: error)
                    return
                }
                completionHandler(success: true, record: record, error: error)
            }
        }
    }
}
extension CloudKitHelper {

    func fetchChallenge(completionHandler: (success: Bool?, record: [CKRecord]?, error: NSError?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "\(RecordType.Challenge)", predicate: predicate)
        privateDB.performQuery(query, inZoneWithID: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record!, error: nil)
        }
    }
    // MARK: - Challenge
    func saveChallenge(challengeDictionary: [String:AnyObject], completionHandler: CompletionHander) {
        let challenge = CKRecord(recordType: "\(RecordType.Challenge)")

        challenge.setValue(challengeDictionary["\(ChallengeKey.challengeDescription)"] as! String, forKey: "\(ChallengeKey.challengeDescription)")
        challenge.setValue(challengeDictionary["\(ChallengeKey.completed)"] as! Bool, forKey: "\(ChallengeKey.completed)")
        challenge.setValue(challengeDictionary["\(ChallengeKey.endDate)"] as! NSDate, forKey: "\(ChallengeKey.endDate)")

        privateDB.saveRecord(challenge) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    func updateChallenge(challengeDescription: String, endDate: NSDate, challengeRecordID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(challengeRecordID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                return
            }

        record!.setValue(challengeDescription, forKey: "\(ChallengeKey.challengeDescription)")
        record!.setValue(endDate, forKey: "\(ChallengeKey.endDate)")

        self.privateDB.saveRecord(record!) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
        }
    }

    func updateCompletedStatusChallenge(challengeID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(challengeID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                return
            }

            if record!.valueForKey("\(ChallengeKey.completed)") as! Int == 0 {
                record!.setValue(1, forKey: "\(ChallengeKey.completed)")
            } else {
                record!.setValue(0, forKey: "\(ChallengeKey.completed)")
            }

            self.privateDB.saveRecord(record!) { (record, error) in
                guard record == record && error == nil else {
                    self.Log.warning(error)
                    completionHandler(success: false, record: nil, error: error)
                    return
                }
                completionHandler(success: true, record: record, error: nil)
            }
        }
    }

    func deleteChallenge(challengeRecordID: CKRecordID, completionHandler: (success: Bool, recordID: CKRecordID!, error: NSError?) -> Void) {
        privateDB.deleteRecordWithID(challengeRecordID) { (recordID, error) in
            guard recordID == recordID && error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, recordID: nil, error: error)
                return
            }
            completionHandler(success: true, recordID: recordID, error: nil)
        }
    }

    //MARK: Subscription

    func fetchNotificationChanges() {
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)

        var notificationIDsToMarkRead = [CKNotificationID]()

        operation.notificationChangedBlock = { (notification: CKNotification) -> Void in
            // Process each notification received
            if notification.notificationType == .Query {
                let queryNotification = notification as! CKQueryNotification
                let reason = queryNotification.queryNotificationReason
                let recordID = queryNotification.recordID

                // Do your process here depending on the reason of the change

                // Add the notification id to the array of processed notifications to mark them as read
                notificationIDsToMarkRead.append(queryNotification.notificationID!)
            }
        }

        operation.fetchNotificationChangesCompletionBlock = { (serverChangeToken: CKServerChangeToken?, operationError: NSError?) -> Void in
            guard operationError == nil else {
                // Handle the error here
                return
            }

            // Mark the notifications as read to avoid processing them again
            let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDsToMarkRead)
            markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) -> Void in
                guard operationError == nil else {
                    // Handle the error here
                    return
                }
            }

            let operationQueue = NSOperationQueue()
            operationQueue.addOperation(markOperation)
        }
        
        let operationQueue = NSOperationQueue()
        operationQueue.addOperation(operation)
    }
}

extension CloudKitHelper {
    // MARK: Subscription
    func subscribeToChallengeCreation() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKSubscription(recordType: "\(RecordType.Challenge)",
                                          predicate: predicate,
                                          options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])

        privateDB.saveSubscription(subscription) { (subscription: CKSubscription?, error: NSError?) -> Void in
            guard error == nil else {
                // Handle the error here
                return
            }
            // Save that we have subscribed successfully to keep track and avoid trying to subscribe again
        }
    }
}
