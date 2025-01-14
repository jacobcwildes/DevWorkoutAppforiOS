//
//  JWWorkoutDayEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/14/25.
//
//

import Foundation
import CoreData


extension JWWorkoutDayEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutDayEntity> {
        return NSFetchRequest<JWWorkoutDayEntity>(entityName: "JWWorkoutDayEntity")
    }

    @NSManaged public var nameAttribute: String?
    @NSManaged public var id: UUID?
    @NSManaged public var workouts: NSSet?
    @NSManaged public var week: JWWeekEntity?

}

// MARK: Generated accessors for workouts
extension JWWorkoutDayEntity {

    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: JWWorkoutEntity)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: JWWorkoutEntity)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)

}

extension JWWorkoutDayEntity : Identifiable {

}
