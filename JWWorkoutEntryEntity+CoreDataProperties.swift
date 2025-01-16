//
//  JWWorkoutEntryEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/15/25.
//
//

import Foundation
import CoreData


extension JWWorkoutEntryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutEntryEntity> {
        return NSFetchRequest<JWWorkoutEntryEntity>(entityName: "JWWorkoutEntryEntity")
    }

    @NSManaged public var entry: String?

}

extension JWWorkoutEntryEntity : Identifiable {

}
