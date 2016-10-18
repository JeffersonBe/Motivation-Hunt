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
    @NSManaged var addedDate: Date
    @NSManaged var theme: String

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(itemVideoID: String, itemTitle: String, itemDescription: String, itemThumbnailsUrl: String, saved: Bool, theme: String, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entity(forEntityName: "VideoItem", in: context)!
        super.init(entity: entity, insertInto: context)
        self.itemVideoID = itemVideoID
        self.itemTitle = itemTitle
        self.itemDescription = itemDescription
        self.itemThumbnailsUrl = itemThumbnailsUrl
        self.saved = saved
        self.theme = theme
    }

    override func awakeFromInsert()  {
        self.uniqueIdentifier = UUID().uuidString
        self.addedDate = Date()
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
