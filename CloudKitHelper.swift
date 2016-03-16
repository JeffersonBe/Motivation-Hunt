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

    typealias CompletionHander = (result: Bool, record: CKRecord!, error: NSError?) -> Void

    init() {
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }

    func fetchUserRecord(recordID: CKRecordID) {
        // Fetch Default Container
        let defaultContainer = CKContainer.defaultContainer()

        // Fetch Private Database
        let privateDatabase = defaultContainer.privateCloudDatabase

        // Fetch User Record
        privateDatabase.fetchRecordWithID(recordID) { (record, error) -> Void in
            if let responseError = error {
                print(responseError)

            } else if let userRecord = record {
                print(userRecord)
            }
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
            if (record != nil) {
                completionHandler(result: true, record: record, error: nil)
            } else {
                completionHandler(result: false, record: nil, error: error)
            }
        }
    }

    func updateFavorites(favoritesID: CKRecordID) {
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
            if (record != nil) {
                completionHandler(result: true, record: record, error: nil)
            } else {
                completionHandler(result: false, record: nil, error: error)
            }
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
                if (record != nil) {
                    completionHandler(result: true, record: record, error: nil)
                } else {
                    completionHandler(result: false, record: nil, error: error)
                }
            }
        }
    }

    func deleteChallenge(challengeID: CKRecordID, completionHandler: (result: Bool, error: NSError?) -> Void) {
        privateDB.deleteRecordWithID(challengeID) { (recordID, error) in
            print(recordID)
            if (recordID != nil) {
                completionHandler(result: true, error: nil)
            } else {
                completionHandler(result: false, error: error)
            }
        }
    }
}
