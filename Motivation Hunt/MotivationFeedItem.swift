//
//  MotivationFeedItem.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 27/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import Foundation
import CoreData

class MotivationFeedItem: NSManagedObject {

    @NSManaged var itemDescription: String
    @NSManaged var itemUrl: String
    @NSManaged var itemID: String
    @NSManaged var saved: Bool

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(itemDescription: String, itemUrl: String, itemID: String, saved: Bool, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("MotivationFeedItem", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.itemDescription = itemDescription
        self.itemUrl = itemUrl
        self.itemID = itemID
        self.saved = false
    }
}