//
//  JWWorkoutEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/21/25.
//
//

import Foundation
import CoreData


extension JWWorkoutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutEntity> {
        return NSFetchRequest<JWWorkoutEntity>(entityName: "JWWorkoutEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var reps: String?
    @NSManaged public var sets: String?
    @NSManaged public var weight: String?
    @NSManaged public var week: JWWeekEntity?
    @NSManaged public var workoutDay: JWWorkoutDayEntity?
    @NSManaged public var workoutEntry: JWWorkoutEntryEntity?
    @NSManaged public var workoutSets: NSSet?

}

// MARK: Generated accessors for workoutSets
extension JWWorkoutEntity {

    @objc(addWorkoutSetsObject:)
    @NSManaged public func addToWorkoutSets(_ value: JWWorkoutSetEntity)

    @objc(removeWorkoutSetsObject:)
    @NSManaged public func removeFromWorkoutSets(_ value: JWWorkoutSetEntity)

    @objc(addWorkoutSets:)
    @NSManaged public func addToWorkoutSets(_ values: NSSet)

    @objc(removeWorkoutSets:)
    @NSManaged public func removeFromWorkoutSets(_ values: NSSet)

}

extension JWWorkoutEntity : Identifiable {

}
