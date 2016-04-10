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

class CloudKitHelper {
    var container: CKContainer
    var publicDB: CKDatabase
    let privateDB: CKDatabase

    // MARK: - Shared Instance
    static var sharedInstance = CloudKitHelper()

    typealias CompletionHander = (success: Bool, record: CKRecord!, error: NSError?) -> Void

    let Log = Logger()

    init() {
        container = CKContainer.defaultContainer()
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

    func getUserInfo(userRecordID: String, completionHandler: (success: Bool?, error: NSError?, firstName: String) -> ()) {
        container.discoverUserInfoWithUserRecordID(CKRecordID(recordName: userRecordID)) { (CKDiscoveredUserInfo, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, error: error, firstName: "")
                return
            }
            var userContact: CNContact
            userContact = CKDiscoveredUserInfo!.displayContact!
            completionHandler(success: true, error: nil, firstName: userContact.givenName)
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
        let query = CKQuery(recordType: "MotivationFeedItem", predicate: predicate)
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
        let motivationItem = CKRecord(recordType: "MotivationFeedItem")

        motivationItem.setValue(itemID, forKey: "itemID")
        motivationItem.setValue(itemTitle, forKey: "itemTitle")
        motivationItem.setValue(itemDescription, forKey: "itemDescription")
        motivationItem.setValue(itemThumbnailsUrl, forKey: "itemThumbnailsUrl")
        motivationItem.setValue(saved, forKey: "saved")
        motivationItem.setValue(addedDate, forKey: "addedDate")

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
        let predicate = NSPredicate(format: "saved == 1")
        let query = CKQuery(recordType: "MotivationFeedItem", predicate: predicate)
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

            if favorites!.valueForKey("saved") as! Int == 0 {
                favorites!.setValue(1, forKey: "saved")
            } else {
                favorites!.setValue(0, forKey: "saved")
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
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
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
        let challenge = CKRecord(recordType: "Challenge")

        challenge.setValue(challengeDictionary["challengeDescription"] as! String, forKey: "challengeDescription")
        challenge.setValue(challengeDictionary["completed"] as! Bool, forKey: "completed")
        challenge.setValue(challengeDictionary["endDate"] as! NSDate, forKey: "endDate")

        privateDB.saveRecord(challenge) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    func updateCompletedStatusChallenge(challengeID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(challengeID) { (record, error) in
            guard error == nil else {
                self.Log.warning(error)
                return
            }

            if record!.valueForKey("completed") as! Int == 0 {
                record!.setValue(1, forKey: "completed")
            } else {
                record!.setValue(0, forKey: "completed")
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

    func deleteChallenge(challengeID: CKRecordID, completionHandler: (success: Bool, recordID: CKRecordID!, error: NSError?) -> Void) {
        privateDB.deleteRecordWithID(challengeID) { (recordID, error) in
            guard recordID == recordID && error == nil else {
                self.Log.warning(error)
                completionHandler(success: false, recordID: nil, error: error)
                return
            }
            completionHandler(success: true, recordID: recordID, error: nil)
        }
    }
}
