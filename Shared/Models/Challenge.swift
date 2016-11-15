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
    @NSManaged var endDate: Date
    @NSManaged var uniqueIdentifier: String

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(challengeDescription: String, completed: Bool, endDate: Date, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entity(forEntityName: "Challenge", in: context)!
        super.init(entity: entity, insertInto: context)
        self.challengeDescription = challengeDescription
        self.completed = completed
        self.endDate = endDate
    }

    override func awakeFromInsert()  {
        self.uniqueIdentifier = UUID().uuidString
    }
}
