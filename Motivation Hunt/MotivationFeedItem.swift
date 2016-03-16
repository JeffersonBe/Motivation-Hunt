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

    @NSManaged var itemID: String
    @NSManaged var itemTitle: String
    @NSManaged var itemDescription: String
    @NSManaged var itemThumbnailsUrl: String
    @NSManaged var saved: Bool
    @NSManaged var addedDate: NSDate

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(itemTitle: String, itemDescription: String, itemID: String, itemThumbnailsUrl: String, saved: Bool, addedDate: NSDate, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("MotivationFeedItem", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.itemTitle = itemTitle
        self.itemDescription = itemDescription
        self.itemID = itemID
        self.itemThumbnailsUrl = itemThumbnailsUrl
        self.saved = saved
        self.addedDate = addedDate
    }

    var image: UIImage? {
        get {
            return MHClient.Caches.imageCache.imageWithIdentifier(itemID)
        }

        set {
            MHClient.Caches.imageCache.storeImage(newValue, withIdentifier: itemID)
        }
    }
}