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
    case itemVideoID = "itemVideoID"
    case itemTitle = "itemTitle"
    case itemDescription = "itemDescription"
    case itemThumbnailsUrl = "itemThumbnailsUrl"
    case saved = "saved"
    case addedDate = "addedDate"
    case itemRecordID = "itemRecordID"
    case theme = "theme"
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

    typealias CompletionHander = (_ success: Bool, _ record: CKRecord?, _ error: NSError?) -> Void

    let Log = Logger()

    init() {
        container = CKContainer(identifier: MHClient.Constants.CKBaseUrl)
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    // MARK: User

    func isIcloudAvailable() -> Bool {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            return false
        }
        return true
    }

    func requestPermission(_ completionHandler: @escaping (_ granted: Bool, _ error: NSError?) -> ()) {
        container.requestApplicationPermission(CKApplicationPermissions.userDiscoverability, completionHandler: { applicationPermissionStatus, error in

            guard applicationPermissionStatus == CKApplicationPermissionStatus.granted else {
                self.Log.warning(error, applicationPermissionStatus)
                completionHandler(false, error as NSError?)
                return
            }
            completionHandler(true, nil)
        })
    }

    func accountStatus(_ completionHandler: @escaping (_ accountStatus: CKAccountStatus, _ error: NSError?)-> ()) {
        container.accountStatus { (CKAccountStatus, error) in
            guard error == nil else {
                self.Log.warning(error, CKAccountStatus)
                completionHandler(CKAccountStatus, error as NSError?)
                return
            }
            completionHandler(CKAccountStatus, error as NSError?)
        }
    }

    func getUser(_ completionHandler: @escaping (_ success: Bool, _ userRecordID: String?, _ error: NSError?) -> ()) {
        container.fetchUserRecordID { (recordID, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, "", error as NSError?)
                return
            }
            completionHandler(true, recordID?.recordName, nil)
        }
    }

    // MARK: - General call
    func fetchUserRecord(_ recordID: CKRecordID, completionHandler: @escaping CompletionHander) {
        privateDB.fetch(withRecordID: recordID) { (record, error) -> Void in
            guard record == record && error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record, nil)
        }
    }
}

// Mark: MotivationFeedItem

extension CloudKitHelper {

    func fetchAllMotivationFeedItem(_ completionHandler: @escaping (_ success: Bool?, _ record: [CKRecord]?, _ error: NSError?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "\(RecordType.MotivationFeedItem)", predicate: predicate)

        privateDB.perform(query, inZoneWith: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record!, nil)
        }
    }

    func fetchMotivationFeedItem(_ completionHandler: @escaping (_ success: Bool?, _ record: [CKRecord]?, _ error: NSError?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "\(RecordType.MotivationFeedItem)", predicate: predicate)

        privateDB.perform(query, inZoneWith: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record!, nil)
        }
    }

    func savedMotivationItem(_ itemVideoID: String, itemTitle: String, itemDescription: String, itemThumbnailsUrl: String, saved: Bool, addedDate: Date, theme: String, completionHandler: @escaping CompletionHander) {
        let motivationItem = CKRecord(recordType: "\(RecordType.MotivationFeedItem)")

        motivationItem.setValue(itemVideoID,
                                forKey: "\(MotivationFeedItemKey.itemVideoID)")
        motivationItem.setValue(itemTitle,
                                forKey: "\(MotivationFeedItemKey.itemTitle)")
        motivationItem.setValue(itemDescription,
                                forKey: "\(MotivationFeedItemKey.itemDescription)")
        motivationItem.setValue(itemThumbnailsUrl,
                                forKey: "\(MotivationFeedItemKey.itemThumbnailsUrl)")
        motivationItem.setValue(saved,
                                forKey: "\(MotivationFeedItemKey.saved)")
        motivationItem.setValue(addedDate,
                                forKey: "\(MotivationFeedItemKey.addedDate)")
        motivationItem.setValue(theme,
                                forKey: "\(MotivationFeedItemKey.theme)")

        privateDB.save(motivationItem, completionHandler: { (record, error) in
            guard record == record && error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record, nil)
        }) 
    }
}

// MARK: - Favorites

extension CloudKitHelper {

    func fetchFavorites(_ completionHandler: @escaping (_ success: Bool?, _ record: [CKRecord]?, _ error: NSError?) -> Void) {
        let predicate = NSPredicate(format: "\(MotivationFeedItemKey.saved) == 1")
        let query = CKQuery(recordType: "\(RecordType.MotivationFeedItem)", predicate: predicate)

        privateDB.perform(query, inZoneWith: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record!, nil)
        }
    }

    func updateFavorites(_ favoritesID: CKRecordID, completionHandler: @escaping CompletionHander) {
        privateDB.fetch(withRecordID: favoritesID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }

            let favorites = record

            if favorites!.value(forKey: "\(MotivationFeedItemKey.saved)") as! Int == 0 {
                favorites!.setValue(1, forKey: "\(MotivationFeedItemKey.saved)")
            } else {
                favorites!.setValue(0, forKey: "\(MotivationFeedItemKey.saved)")
            }

            self.privateDB.save(favorites!, completionHandler: { (record, error) in
                guard error == nil else {
                    self.Log.warning(error)
                    completionHandler(false, nil, error as NSError?)
                    return
                }
                completionHandler(true, record, error as NSError?)
            }) 
        }
    }
}
extension CloudKitHelper {

    func fetchChallenge(_ completionHandler: @escaping (_ success: Bool?, _ record: [CKRecord]?, _ error: NSError?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "\(RecordType.Challenge)", predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record!, nil)
        }
    }

    // MARK: - Challenge
    func saveChallenge(_ challengeDictionary: [String:AnyObject], completionHandler: @escaping CompletionHander) {
        let challenge = CKRecord(recordType: "\(RecordType.Challenge)")

        challenge.setValue(challengeDictionary["\(ChallengeKey.challengeDescription)"] as! String,
                           forKey: "\(ChallengeKey.challengeDescription)")
        challenge.setValue(challengeDictionary["\(ChallengeKey.completed)"] as! Bool,
                           forKey: "\(ChallengeKey.completed)")
        challenge.setValue(challengeDictionary["\(ChallengeKey.endDate)"] as! Date,
                           forKey: "\(ChallengeKey.endDate)")

        privateDB.save(challenge, completionHandler: { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record, nil)
        }) 
    }

    func updateChallenge(_ challengeDictionary: [String:AnyObject], completionHandler: @escaping CompletionHander) {

        privateDB.fetch(withRecordID: CKRecordID(recordName: challengeDictionary["challengeRecordID"] as! String)) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                return
            }

            record!.setValue(challengeDictionary["challengeDescription"],
                         forKey: "\(ChallengeKey.challengeDescription)")
            record!.setValue(challengeDictionary["endDate"],
                         forKey: "\(ChallengeKey.endDate)")

        self.privateDB.save(record!, completionHandler: { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, record, nil)
        }) 
        }
    }

    func updateCompletedStatusChallenge(_ challengeID: CKRecordID, completionHandler: @escaping CompletionHander) {
        privateDB.fetch(withRecordID: challengeID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                return
            }

            if record!.value(forKey: "\(ChallengeKey.completed)") as! Int == 0 {
                record!.setValue(true, forKey: "\(ChallengeKey.completed)")
            } else {
                record!.setValue(false, forKey: "\(ChallengeKey.completed)")
            }

            self.privateDB.save(record!, completionHandler: { (record, error) in
                guard record == record && error == nil else {
                    self.Log.warning(error)
                    completionHandler(false, nil, error as NSError?)
                    return
                }
                completionHandler(true, record, nil)
            }) 
        }
    }

    func deleteChallenge(_ challengeRecordID: CKRecordID, completionHandler: @escaping (_ success: Bool, _ recordID: CKRecordID?, _ error: NSError?) -> Void) {
        privateDB.delete(withRecordID: challengeRecordID) { (recordID, error) in
            guard recordID == recordID && error == nil else {
                self.Log.warning(error)
                completionHandler(false, nil, error as NSError?)
                return
            }
            completionHandler(true, recordID, nil)
        }
    }

    //MARK: Subscription

    func fetchNotificationChanges() {
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)

        var notificationIDsToMarkRead = [CKNotificationID]()

        operation.notificationChangedBlock = { (notification) -> Void in
            // Process each notification received
            if notification.notificationType == .query {
                let queryNotification = notification as! CKQueryNotification
//                let reason = queryNotification.queryNotificationReason
//                let recordID = queryNotification.recordID

                // Do your process here depending on the reason of the change

                // Add the notification id to the array of processed notifications to mark them as read
                notificationIDsToMarkRead.append(queryNotification.notificationID!)
            }
        }

        operation.fetchNotificationChangesCompletionBlock = { (newToken, error) -> Void in
            
            guard error == nil else {
                // Handle the error here
                return
            }

            // Mark the notifications as read to avoid processing them again
            let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDsToMarkRead)
            
            markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead, operationError) -> Void in
                guard operationError == nil else {
                    // Handle the error here
                    return
                }
            }

            let operationQueue = OperationQueue()
            operationQueue.addOperation(markOperation)
        }
        
        let operationQueue = OperationQueue()
        operationQueue.addOperation(operation)
    }
}

extension CloudKitHelper {
    // MARK: Subscription
    func subscribeToChallengeCreation() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKQuerySubscription(recordType: "\(RecordType.Challenge)",
                                          predicate: predicate,
                                          options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])

        privateDB.save(subscription, completionHandler: { (subscription: CKSubscription?, error: NSError?) -> Void in
            guard error == nil else {
                // Handle the error here
                return
            }
            // Save that we have subscribed successfully to keep track and avoid trying to subscribe again
        } as! (CKSubscription?, Error?) -> Void) 
    }
}
