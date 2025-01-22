//
//  JWWeekEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/21/25.
//
//

import Foundation
import CoreData


extension JWWeekEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWeekEntity> {
        return NSFetchRequest<JWWeekEntity>(entityName: "JWWeekEntity")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var weekNumber: Int32
    @NSManaged public var workouts: NSSet?

}

// MARK: Generated accessors for workouts
extension JWWeekEntity {

    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: JWWorkoutEntity)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: JWWorkoutEntity)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)

}

extension JWWeekEntity : Identifiable {

}
