//
//  Item.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 16/08/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import CoreData

class Item: NSManagedObject {

    @NSManaged var uniqueIdentifier: String
    @NSManaged var item: AnyObject
    @NSManaged var theme: String

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(item: AnyObject, theme: Theme.themeName, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Item", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.item = item
        self.theme = theme.rawValue
    }

    override func awakeFromInsert()  {
        self.uniqueIdentifier = NSUUID().UUIDString
    }
}
