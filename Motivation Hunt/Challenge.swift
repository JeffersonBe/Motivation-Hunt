//
//  Challenge.swift
//  Motivation Hunt
//
//  Created by Jefferson Bonnaire on 07/02/2016.
//  Copyright © 2016 Jefferson Bonnaire. All rights reserved.
//

import UIKit
import CoreData

class Challenge: NSManagedObject {

    @NSManaged var challengeDescription: String
    @NSManaged var completed: Bool
    @NSManaged var endDate: NSDate
    @NSManaged var challengeRecordID: String

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(challengeDescription: String, completed: Bool, endDate: NSDate, challengeRecordID: String, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Challenge", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.challengeDescription = challengeDescription
        self.completed = completed
        self.endDate = endDate
        self.challengeRecordID = challengeRecordID
    }
}
