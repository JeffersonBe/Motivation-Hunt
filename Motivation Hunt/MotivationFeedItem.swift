//
//  MotivationFeedItem.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData

class MotivationFeedItem: NSManagedObject {

    @NSManaged var itemRecordID: String
    @NSManaged var itemVideoID: String
    @NSManaged var itemTitle: String
    @NSManaged var itemDescription: String
    @NSManaged var itemThumbnailsUrl: String
    @NSManaged var saved: Bool
    @NSManaged var addedDate: NSDate
    @NSManaged var theme: String

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(itemRecordID: String, itemVideoID: String, itemTitle: String, itemDescription: String, itemThumbnailsUrl: String, saved: Bool, addedDate: NSDate, theme: String, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("MotivationFeedItem", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.itemRecordID = itemRecordID
        self.itemVideoID = itemVideoID
        self.itemTitle = itemTitle
        self.itemDescription = itemDescription
        self.itemThumbnailsUrl = itemThumbnailsUrl
        self.saved = saved
        self.addedDate = addedDate
        self.theme = theme
    }

    var image: UIImage? {
        get {
            return MHClient.Caches.imageCache.imageWithIdentifier(itemVideoID)
        }

        set {
            MHClient.Caches.imageCache.storeImage(newValue, withIdentifier: itemVideoID)
        }
    }
}
