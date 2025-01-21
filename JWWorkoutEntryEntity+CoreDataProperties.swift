//
//  JWWorkoutEntryEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/21/25.
//
//

import Foundation
import CoreData


extension JWWorkoutEntryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutEntryEntity> {
        return NSFetchRequest<JWWorkoutEntryEntity>(entityName: "JWWorkoutEntryEntity")
    }

    @NSManaged public var entry: String?
    @NSManaged public var workoutEntry: NSSet?

}

// MARK: Generated accessors for workoutEntry
extension JWWorkoutEntryEntity {

    @objc(addWorkoutEntryObject:)
    @NSManaged public func addToWorkoutEntry(_ value: JWWorkoutEntity)

    @objc(removeWorkoutEntryObject:)
    @NSManaged public func removeFromWorkoutEntry(_ value: JWWorkoutEntity)

    @objc(addWorkoutEntry:)
    @NSManaged public func addToWorkoutEntry(_ values: NSSet)

    @objc(removeWorkoutEntry:)
    @NSManaged public func removeFromWorkoutEntry(_ values: NSSet)

}

extension JWWorkoutEntryEntity : Identifiable {

}
