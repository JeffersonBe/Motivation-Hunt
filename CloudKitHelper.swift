//
//  CloudKitHelper.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 13/03/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitHelper {
    var container : CKContainer
    var publicDB : CKDatabase
    let privateDB : CKDatabase

    // MARK: - Shared Instance
    static var sharedInstance = CloudKitHelper()

    typealias CompletionHander = (success: Bool, record: CKRecord!, error: NSError?) -> Void

    init() {
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    // MARK: User

    func requestPermission(completionHandler: (granted: Bool) -> ()) {
        container.requestApplicationPermission(CKApplicationPermissions.UserDiscoverability, completionHandler: { applicationPermissionStatus, error in
            guard applicationPermissionStatus == CKApplicationPermissionStatus.Granted else {
                completionHandler(granted: false)
                return
            }
            completionHandler(granted: true)
        })
    }

    func getUser(completionHandler: (success: Bool, userRecordID: String) -> ()) {
        container.fetchUserRecordIDWithCompletionHandler { (recordID, error) in
            guard error != nil else {
                completionHandler(success: false, userRecordID: "")
                return
            }

            self.privateDB.fetchRecordWithID(recordID!, completionHandler: { (CKRecord, NSError) in
                guard error != nil else {
                    completionHandler(success: false, userRecordID: "")
                    return
                }
                completionHandler(success: true, userRecordID: recordID!.recordName)
            })
        }
    }

    func getUserInfo(userRecordID: String, completionHandler: (success: Bool, firstName: String) -> ()) {
        container.discoverUserInfoWithUserRecordID(CKRecordID(recordName: userRecordID)) { (CKDiscoveredUserInfo, error) in
            guard error != nil else {
                completionHandler(success: false, firstName: "")
                return
            }
                var userContact: CNContact
                userContact = CKDiscoveredUserInfo!.displayContact!
                completionHandler(success: true, firstName: userContact.givenName)
        }
    }

    // MARK: - General call
    func fetchUserRecord(recordID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(recordID) { (record, error) -> Void in
            guard record == record && error != nil else {
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    // MARK: - Favorites
    func savedMotivationItem(motivationDictionary: [String:AnyObject], completionHandler: CompletionHander) {
        let motivationItem = CKRecord(recordType: "MotivationFeedItem")

        motivationItem.setValue(motivationDictionary["itemID"] as! String, forKey: "itemID")
        motivationItem.setValue(motivationDictionary["itemTitle"] as! String, forKey: "itemTitle")
        motivationItem.setValue(motivationDictionary["itemDescription"] as! String, forKey: "itemDescription")
        motivationItem.setValue(motivationDictionary["itemThumbnailsUrl"] as! String, forKey: "itemThumbnailsUrl")
        motivationItem.setValue(motivationDictionary["saved"] as! Bool, forKey: "saved")
        motivationItem.setValue(motivationDictionary["addedDate"] as! NSDate, forKey: "addedDate")

        privateDB.saveRecord(motivationItem) { (record, error) in
            guard record == record && error != nil else {
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    func updateFavorites(favoritesID: CKRecordID, completionHandler: CompletionHander) {
        var favorites: CKRecord!
        privateDB.fetchRecordWithID(favoritesID) { (record, error) in
            if (record == nil) {
                favorites = record
            } else {
                return
            }
        }

        if favorites.valueForKey("saved") as! Int == 0  {
            favorites.setValue(1, forKey: "saved")
        } else {
            favorites.setValue(0, forKey: "saved")
        }

        privateDB.saveRecord(favorites) { (record, error) in
            if (record != nil) {
                print("Saved to cloud kit: \(record)")
            } else {
                print("Error on saveChallenge: \(error)")
            }
        }
    }

    // MARK: - Challenge
    func saveChallenge(challengeDictionary: [String:AnyObject], completionHandler: CompletionHander) {
        let challenge = CKRecord(recordType: "Challenge")

        challenge.setValue(challengeDictionary["challengeDescription"] as! String, forKey: "challengeDescription")
        challenge.setValue(challengeDictionary["completed"] as! Bool, forKey: "completed")
        challenge.setValue(challengeDictionary["endDate"] as! NSDate, forKey: "endDate")

        privateDB.saveRecord(challenge) { (record, error) in
            guard record == record && error != nil else {
                completionHandler(success: false, record: nil, error: error)
                return
            }
            completionHandler(success: true, record: record, error: nil)
        }
    }

    func updateCompletedStatusChallenge(challengeID: CKRecordID, completionHandler: CompletionHander) {
        privateDB.fetchRecordWithID(challengeID) { (record, error) in
            guard record == record else {
                return
            }
                if record!.valueForKey("completed") as! Int == 0  {
                    record!.setValue(1, forKey: "completed")
                } else {
                    record!.setValue(0, forKey: "completed")
                }

            self.privateDB.saveRecord(record!) { (record, error) in
                guard record == record && error != nil else {
                    completionHandler(success: false, record: nil, error: error)
                    return
                }
                completionHandler(success: true, record: record, error: nil)
            }
        }
    }

    func deleteChallenge(challengeID: CKRecordID, completionHandler: (success: Bool, recordID: CKRecordID!, error: NSError?) -> Void) {
        privateDB.deleteRecordWithID(challengeID) { (recordID, error) in
            guard recordID == recordID && error != nil else {
                completionHandler(success: false, recordID: nil, error: error)
                return
            }
            completionHandler(success: true, recordID: recordID, error: nil)
        }
    }
}
