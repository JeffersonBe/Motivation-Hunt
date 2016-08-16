//
//  VideoItem.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData

class VideoItem: NSManagedObject {

    @NSManaged var uniqueIdentifier: String
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

    init(itemVideoID: String, itemTitle: String, itemDescription: String, itemThumbnailsUrl: String, saved: Bool, theme: Theme.themeName, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("VideoItem", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.itemVideoID = itemVideoID
        self.itemTitle = itemTitle
        self.itemDescription = itemDescription
        self.itemThumbnailsUrl = itemThumbnailsUrl
        self.saved = saved
        self.theme = theme.rawValue
    }

    override func awakeFromInsert()  {
        self.uniqueIdentifier = NSUUID().UUIDString
        self.addedDate = NSDate()
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
